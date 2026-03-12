import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfigService } from '../../config/config.service';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);
  private embeddingModel: string = 'text-embedding-3-small';
  private embeddingDimensions: number = 1536;
  private openaiApiKey: string | null = null;
  private apiBaseUrl: string = 'https://api.openai.com/v1';

  constructor(
    private configService: ConfigService,
    private appConfigService: AppConfigService,
    private prisma: PrismaService,
  ) {
    // Initialize API key synchronously (from environment)
    this.initializeApiKey();
    // Initialize async config (model, dimensions from database)
    this.initializeConfig();
  }

  private initializeApiKey() {
    // Try to get OpenAI API key from environment or config
    const rawKey = this.configService.get<string>('OPENAI_API_KEY');
    this.openaiApiKey = rawKey ? rawKey.trim() : null;

    // Detect if using OpenRouter (keys start with sk-or-v1-)
    if (this.openaiApiKey?.startsWith('sk-or-v1-')) {
      this.apiBaseUrl = 'https://openrouter.ai/api/v1';
      this.logger.log('Using OpenRouter API endpoint');
    } else {
      this.apiBaseUrl = 'https://api.openai.com/v1';
    }

    if (!this.openaiApiKey) {
      this.logger.warn(
        'OpenAI API key not found. Embedding generation will fail. Set OPENAI_API_KEY in environment or app_config.',
      );
    } else {
      this.logger.log(
        `API key configured (${this.openaiApiKey.substring(0, 10)}...), using ${this.apiBaseUrl}`,
      );
    }
  }

  private async initializeConfig() {
    try {
      const modelConfig = await this.appConfigService.getConfigByKey(
        'ai_embedding_model',
      );
      if (modelConfig) {
        this.embeddingModel = modelConfig.configValue;
      }

      const dimensionsConfig = await this.appConfigService.getConfigByKey(
        'ai_embedding_dimensions',
      );
      if (dimensionsConfig) {
        this.embeddingDimensions = parseInt(dimensionsConfig.configValue, 10);
      }
    } catch (error) {
      this.logger.error('Error initializing embedding config:', error);
    }
  }

  /**
   * Generate embedding for a single text
   */
  async generateEmbedding(text: string): Promise<number[]> {
    if (!text || text.trim().length === 0) {
      throw new Error('Text cannot be empty');
    }

    if (!this.openaiApiKey) {
      throw new Error('OpenAI API key not configured');
    }

    try {
      const response = await fetch(`${this.apiBaseUrl}/embeddings`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.openaiApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.embeddingModel,
          input: text.trim(),
          dimensions: this.embeddingDimensions,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(
          `OpenAI API error: ${error.error?.message || response.statusText}`,
        );
      }

      const data = await response.json();
      return data.data[0].embedding;
    } catch (error: any) {
      this.logger.error('Error generating embedding:', error);
      throw new Error(`Failed to generate embedding: ${error.message}`);
    }
  }

  /**
   * Generate embeddings for multiple texts in batch
   */
  async generateEmbeddingsBatch(texts: string[]): Promise<number[][]> {
    if (!texts || texts.length === 0) {
      return [];
    }

    if (!this.openaiApiKey) {
      throw new Error('OpenAI API key not configured');
    }

    // Filter out empty texts
    const validTexts = texts.filter((text) => text && text.trim().length > 0);
    if (validTexts.length === 0) {
      return [];
    }

    try {
      const response = await fetch(`${this.apiBaseUrl}/embeddings`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.openaiApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.embeddingModel,
          input: validTexts.map((text) => text.trim()),
          dimensions: this.embeddingDimensions,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(
          `OpenAI API error: ${error.error?.message || response.statusText}`,
        );
      }

      const data = await response.json();
      return data.data.map((item: any) => item.embedding);
    } catch (error: any) {
      this.logger.error('Error generating batch embeddings:', error);
      throw new Error(`Failed to generate embeddings: ${error.message}`);
    }
  }

  /**
   * Generate embedding and store it in a table column
   */
  async generateAndStoreEmbedding(
    tableName: string,
    recordId: bigint,
    columnName: string,
    text: string,
  ): Promise<void> {
    try {
      const embedding = await this.generateEmbedding(text);
      const embeddingArray = `[${embedding.join(',')}]`;

      await this.prisma.$executeRawUnsafe(
        `UPDATE ${tableName} SET ${columnName} = $1::vector WHERE id = $2`,
        embeddingArray,
        recordId,
      );
    } catch (error: any) {
      this.logger.error(
        `Error storing embedding for ${tableName}.${columnName}:`,
        error,
      );
      throw error;
    }
  }

  /**
   * Get embedding dimensions
   */
  getDimensions(): number {
    return this.embeddingDimensions;
  }

  /**
   * Get embedding model name
   */
  getModel(): string {
    return this.embeddingModel;
  }
}

