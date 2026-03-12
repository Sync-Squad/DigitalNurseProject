import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { VectorSearchService } from './vector-search.service';
import { EmbeddingService } from './embedding.service';
import { AppConfigService } from '../../config/config.service';
import { ChatMessageDto } from '../dto/chat-message.dto';

interface ConversationContext {
  medications: any[];
  vitals: any[];
  notes: any[];
  dietLogs: any[];
  exerciseLogs: any[];
}

@Injectable()
export class AIAssistantService {
  private readonly logger = new Logger(AIAssistantService.name);
  private openRouterApiKey: string | null = null;
  private readonly openRouterModel: string = 'openai/gpt-oss-20b:free';

  constructor(
    private prisma: PrismaService,
    private vectorSearchService: VectorSearchService,
    private embeddingService: EmbeddingService,
    private appConfigService: AppConfigService,
    private configService: ConfigService,
  ) {
    this.initializeOpenRouterKey();
  }

  private initializeOpenRouterKey() {
    try {
      this.openRouterApiKey = this.configService.get<string>('OPENAI_API_KEY') || null;
      if (!this.openRouterApiKey) {
        this.logger.warn('OpenRouter API key not found. AI Assistant will not work. Set OPENAI_API_KEY in environment.');
      } else {
        this.logger.log('OpenRouter API key initialized successfully');
      }
    } catch (error) {
      this.logger.error('Error initializing OpenRouter API key:', error);
    }
  }

  /**
   * Process a chat message and generate AI response
   */
  async chat(
    userId: bigint,
    dto: ChatMessageDto,
  ): Promise<{ message: string; conversationId: string; sources?: any[] }> {
    if (!this.openRouterApiKey) {
      throw new Error('OpenRouter API key not configured');
    }

    // Get or create conversation
    let conversationId = dto.conversationId;
    if (!conversationId) {
      const conversation = await this.createConversation(
        userId,
        dto.elderUserId,
      );
      conversationId = conversation.conversationId;
    }

    // Retrieve relevant context using RAG
    const context = await this.retrieveContext(
      userId,
      dto.elderUserId,
      dto.message,
    );

    // Build system prompt with context (without user question)
    const systemPrompt = this.buildSystemPrompt(context);

    // Get conversation history for context
    const conversationHistory = await this.getConversationHistory(conversationId);

    // Generate response using OpenRouter
    const response = await this.generateResponse(
      dto.message,
      systemPrompt,
      conversationHistory,
    );

    // Store messages
    await this.storeMessage(conversationId, 'user', dto.message);
    await this.storeMessage(conversationId, 'assistant', response.message, {
      sources: response.sources,
    });

    // Update conversation
    await this.updateConversation(conversationId);

    return {
      message: response.message,
      conversationId: conversationId.toString(),
      sources: response.sources,
    };
  }

  /**
   * Retrieve relevant context using vector search (RAG)
   */
  private async retrieveContext(
    userId: bigint,
    elderUserId?: bigint,
    query?: string,
  ): Promise<ConversationContext> {
    const context: ConversationContext = {
      medications: [],
      vitals: [],
      notes: [],
      dietLogs: [],
      exerciseLogs: [],
    };

    // If no elderUserId provided, use the authenticated user's ID
    // This handles the case where a regular patient (not caregiver) is asking
    const targetUserId = elderUserId || userId;

    if (!targetUserId) {
      return context;
    }

    if (query) {
      // Use semantic search to find relevant information
      try {
        const searchResults = await this.vectorSearchService.searchAll({
          query,
          elderUserId: targetUserId,
          limit: 10,
        });

        this.logger.debug(`Vector search found ${searchResults.length} results for query: "${query}"`);

        // Group results by entity type
        searchResults.forEach((result) => {
          switch (result.entityType) {
            case 'medications':
              context.medications.push(result);
              break;
            case 'vital_measurements':
              context.vitals.push(result);
              break;
            case 'caregiver_notes':
              context.notes.push(result);
              break;
            case 'diet_logs':
              context.dietLogs.push(result);
              break;
            case 'exercise_logs':
              context.exerciseLogs.push(result);
              break;
          }
        });
      } catch (error) {
        this.logger.warn('Vector search failed, falling back to recent data:', error);
      }
    }

    // Fallback: Get recent data if search returned no results or if no query
    // This ensures we always have some context even if embeddings don't exist
    if (context.vitals.length === 0 && context.medications.length === 0 && context.notes.length === 0) {
      this.logger.debug('No search results found, fetching recent data as fallback');
      try {
        const [medications, vitals, notes] = await Promise.all([
          this.prisma.medication.findMany({
            where: { elderUserId: targetUserId },
            take: 10,
            orderBy: { createdAt: 'desc' },
          }),
          this.prisma.vitalMeasurement.findMany({
            where: { elderUserId: targetUserId },
            take: 10,
            orderBy: { recordedAt: 'desc' },
          }),
          this.prisma.caregiverNote.findMany({
            where: { elderUserId: targetUserId },
            take: 10,
            orderBy: { createdAt: 'desc' },
          }),
        ]);

        context.medications = medications;
        context.vitals = vitals;
        context.notes = notes;

        this.logger.debug(`Fallback: Found ${vitals.length} vitals, ${medications.length} medications, ${notes.length} notes`);
      } catch (error) {
        this.logger.error('Error fetching fallback data:', error);
      }
    }

    return context;
  }

  /**
   * Build system prompt with context for OpenRouter
   */
  private buildSystemPrompt(context: ConversationContext): string {
    let systemPrompt = `You are a helpful AI health assistant for Digital Nurse. Answer the user's questions based on their health data.

Relevant Health Data:
`;

    if (context.medications.length > 0) {
      systemPrompt += `\nMedications:\n`;
      context.medications.forEach((med: any) => {
        const name = med.medicationName || med.metadata?.medicationName || 'Medication';
        const content = med.content || med.instructions || med.notes || '';
        systemPrompt += `- ${name}: ${content}\n`;
      });
    }

    if (context.vitals.length > 0) {
      systemPrompt += `\nRecent Vital Measurements:\n`;
      context.vitals.forEach((vital: any) => {
        // Handle both search results and direct database results
        const kindCode = vital.kindCode || vital.metadata?.kindCode || 'Vital';
        const value1 = vital.value1;
        const value2 = vital.value2;
        const valueText = vital.valueText;
        const notes = vital.notes;
        const recordedAt = vital.recordedAt || vital.metadata?.recordedAt;
        
        let vitalInfo = kindCode;
        if (value1 !== null && value1 !== undefined) {
          vitalInfo += `: ${value1}`;
          if (value2 !== null && value2 !== undefined) {
            vitalInfo += `/${value2}`;
          }
        } else if (valueText) {
          vitalInfo += `: ${valueText}`;
        }
        if (notes) {
          vitalInfo += ` (${notes})`;
        }
        if (recordedAt) {
          const date = new Date(recordedAt).toLocaleDateString();
          vitalInfo += ` - ${date}`;
        }
        
        // If it's from search results, use content
        if (vital.content && !value1 && !valueText) {
          vitalInfo = `${kindCode}: ${vital.content}`;
        }
        
        systemPrompt += `- ${vitalInfo}\n`;
      });
    }

    if (context.notes.length > 0) {
      systemPrompt += `\nCaregiver Notes:\n`;
      context.notes.forEach((note: any) => {
        const content = note.content || note.noteText || '';
        const createdAt = note.createdAt || note.metadata?.createdAt;
        let noteInfo = content;
        if (createdAt) {
          const date = new Date(createdAt).toLocaleDateString();
          noteInfo += ` (${date})`;
        }
        systemPrompt += `- ${noteInfo}\n`;
      });
    }

    if (context.vitals.length === 0 && context.medications.length === 0 && context.notes.length === 0) {
      systemPrompt += `\nNo recent health data available.`;
    }

    systemPrompt += `\nInstructions:
- Answer based on the provided health data above
- Be specific and reference actual values when available
- If the user asks about specific vitals (like blood pressure), look for those in the data above
- Be concise and helpful
- If you don't have enough information, say so clearly
- Always recommend consulting healthcare providers for medical advice
- Use a friendly, supportive tone`;

    return systemPrompt;
  }

  /**
   * Get conversation history for context
   */
  private async getConversationHistory(conversationId: bigint): Promise<Array<{ role: string; content: string }>> {
    try {
      const messages = await this.prisma.$queryRawUnsafe(
        `SELECT role, content FROM ai_conversation_messages 
         WHERE conversation_id = ${conversationId} 
         ORDER BY created_at ASC 
         LIMIT 10`,
      );

      return (messages as any[]).map((msg) => ({
        role: msg.role === 'assistant' ? 'assistant' : 'user',
        content: msg.content,
      }));
    } catch (error) {
      this.logger.warn('Error fetching conversation history:', error);
      return [];
    }
  }

  /**
   * Generate response using OpenRouter API
   */
  private async generateResponse(
    userMessage: string,
    systemPrompt: string,
    conversationHistory: Array<{ role: string; content: string }> = [],
  ): Promise<{
    message: string;
    sources?: any[];
  }> {
    try {
      // Build messages array with system prompt, conversation history, and current user message
      const messages = [
        {
          role: 'system',
          content: systemPrompt,
        },
        ...conversationHistory,
        {
          role: 'user',
          content: userMessage,
        },
      ];

      const response = await fetch(
        'https://openrouter.ai/api/v1/chat/completions',
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.openRouterApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: this.openRouterModel,
            messages: messages,
          }),
        },
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(
          `OpenRouter API error: ${error.error?.message || response.statusText}`,
        );
      }

      const data = await response.json();
      const message =
        data.choices?.[0]?.message?.content ||
        'I apologize, but I could not generate a response.';

      return { message };
    } catch (error: any) {
      this.logger.error('Error generating AI response:', error);
      throw new Error(`Failed to generate response: ${error.message}`);
    }
  }

  /**
   * Create a new conversation
   */
  private async createConversation(
    userId: bigint,
    elderUserId?: bigint,
  ): Promise<{ conversationId: bigint }> {
    const elderUserIdValue = elderUserId ? `${elderUserId}` : 'NULL';
    
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO ai_conversations (user_id, elder_user_id, created_at, updated_at)
       VALUES (${userId}, ${elderUserIdValue}, NOW(), NOW())`,
    );

    const conversations = await this.prisma.$queryRawUnsafe(
      `SELECT conversation_id FROM ai_conversations 
       WHERE user_id = ${userId} 
       ORDER BY created_at DESC LIMIT 1`,
    );

    return {
      conversationId: BigInt((conversations as any[])[0].conversation_id),
    };
  }

  /**
   * Store a message in the conversation
   */
  private async storeMessage(
    conversationId: bigint,
    role: 'user' | 'assistant',
    content: string,
    metadata?: any,
  ) {
    // Escape single quotes in content and metadata to prevent SQL injection
    const escapedContent = content.replace(/'/g, "''");
    const metadataJson = JSON.stringify(metadata || {}).replace(/'/g, "''");
    
    await this.prisma.$executeRawUnsafe(
      `INSERT INTO ai_conversation_messages 
       (conversation_id, role, content, metadata, created_at)
       VALUES (${conversationId}, '${role}', '${escapedContent}', '${metadataJson}'::jsonb, NOW())`,
    );
  }

  /**
   * Update conversation timestamp
   */
  private async updateConversation(conversationId: bigint) {
    await this.prisma.$executeRawUnsafe(
      `UPDATE ai_conversations 
       SET updated_at = NOW() 
       WHERE conversation_id = ${conversationId}`,
    );
  }

  /**
   * Get conversation history
   */
  async getConversation(conversationId: bigint, userId: bigint) {
    const conversation = await this.prisma.$queryRawUnsafe(
      `SELECT * FROM ai_conversations 
       WHERE conversation_id = ${conversationId} AND user_id = ${userId}`,
    );

    if (!conversation || (conversation as any[]).length === 0) {
      return null;
    }

    const messages = await this.prisma.$queryRawUnsafe(
      `SELECT * FROM ai_conversation_messages 
       WHERE conversation_id = ${conversationId} 
       ORDER BY created_at ASC`,
    );

    const conv = (conversation as any[])[0];
    const msgs = (messages as any[]).map((msg) => ({
      ...msg,
      conversation_id: msg.conversation_id?.toString(),
    }));

    return {
      conversation: {
        ...conv,
        conversation_id: conv.conversation_id?.toString(),
        user_id: conv.user_id?.toString(),
        elder_user_id: conv.elder_user_id?.toString(),
      },
      messages: msgs,
    };
  }

  /**
   * Get all conversations for a user
   */
  async getConversations(userId: bigint, elderUserId?: bigint) {
    let query = `SELECT * FROM ai_conversations WHERE user_id = ${userId}`;
    if (elderUserId) {
      query += ` AND elder_user_id = ${elderUserId}`;
    }
    query += ` ORDER BY updated_at DESC`;

    const conversations = await this.prisma.$queryRawUnsafe(query);
    return (conversations as any[]).map((conv) => ({
      ...conv,
      conversation_id: conv.conversation_id?.toString(),
      user_id: conv.user_id?.toString(),
      elder_user_id: conv.elder_user_id?.toString(),
    }));
  }
}

