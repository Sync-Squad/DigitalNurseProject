import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AppConfigService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get a config value by key
   */
  async getConfigByKey(configKey: string) {
    return this.prisma.appConfig.findUnique({
      where: { configKey, isActive: true },
      select: {
        configKey: true,
        configValue: true,
        description: true,
      },
    });
  }

  /**
   * Get the AI API key (checks 'ai_api_key' then 'gemini_api_key')
   */
  async getAiApiKey() {
    const configs = await this.prisma.appConfig.findMany({
      where: {
        configKey: { in: ['ai_api_key', 'gemini_api_key'] },
        isActive: true,
      },
      orderBy: { configKey: 'asc' }, // ai_api_key comes before gemini_api_key
    });

    if (configs.length === 0) return null;

    // Prefer ai_api_key if both exist
    const aiKey = configs.find(c => c.configKey === 'ai_api_key');
    const geminiKey = configs.find(c => c.configKey === 'gemini_api_key');

    return aiKey?.configValue || geminiKey?.configValue || null;
  }

  /**
   * Get the Gemini API key specifically (Legacy)
   */
  async getGeminiApiKey() {
    return this.getAiApiKey();
  }

  /**
   * Get all active config values
   */
  async getAllConfig() {
    return this.prisma.appConfig.findMany({
      where: { isActive: true },
      select: {
        configKey: true,
        configValue: true,
        description: true,
      },
    });
  }

  /**
   * Upsert a config value (create or update)
   */
  async upsertConfig(
    configKey: string,
    configValue: string,
    description?: string,
  ) {
    return this.prisma.appConfig.upsert({
      where: { configKey },
      update: {
        configValue,
        description,
        updatedAt: new Date(),
      },
      create: {
        configKey,
        configValue,
        description,
        isActive: true,
      },
    });
  }

  /**
   * Deactivate a config value (soft delete)
   */
  /**
   * Get multiple config values by keys
   */
  async getConfigsByKeys(keys: string[]) {
    return this.prisma.appConfig.findMany({
      where: { configKey: { in: keys }, isActive: true },
    });
  }
}
