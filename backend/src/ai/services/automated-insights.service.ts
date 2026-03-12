import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { AIInsightsService } from './ai-insights.service';
import { AppConfigService } from '../../config/config.service';
import {
  InsightType,
  InsightPriority,
  InsightCategory,
} from '../dto/generate-insight.dto';

@Injectable()
export class AutomatedInsightsService {
  private readonly logger = new Logger(AutomatedInsightsService.name);
  private isEnabled = true;

  constructor(
    private prisma: PrismaService,
    private insightsService: AIInsightsService,
    private appConfigService: AppConfigService,
  ) {
    this.initializeConfig();
  }

  private async initializeConfig() {
    try {
      const config = await this.appConfigService.getConfigByKey(
        'ai_insight_generation_enabled',
      );
      if (config) {
        this.isEnabled = config.configValue === 'true';
      }
    } catch (error) {
      this.logger.error('Error initializing automated insights config:', error);
    }
  }

  /**
   * Generate daily insights for all active users
   * Runs daily at 2 AM
   */
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async generateDailyInsights() {
    if (!this.isEnabled) {
      this.logger.log('Automated insight generation is disabled');
      return;
    }

    this.logger.log('Starting daily insight generation...');

    try {
      // Get all active users who are patients (elder users)
      const users = await this.prisma.user.findMany({
        where: {
          status: 'active',
        },
        select: {
          userId: true,
        },
      });

      let generated = 0;
      let errors = 0;

      for (const user of users) {
        try {
          // Generate medication adherence insight
          await this.insightsService.generateInsight(
            {
              insightType: InsightType.MEDICATION_ADHERENCE,
              elderUserId: user.userId,
              priority: InsightPriority.MEDIUM,
              category: InsightCategory.MEDICATION,
            },
            user.userId,
          );

          // Generate health trend insight
          await this.insightsService.generateInsight(
            {
              insightType: InsightType.HEALTH_TREND,
              elderUserId: user.userId,
              priority: InsightPriority.MEDIUM,
              category: InsightCategory.VITALS,
            },
            user.userId,
          );

          // Generate recommendations
          await this.insightsService.generateInsight(
            {
              insightType: InsightType.RECOMMENDATION,
              elderUserId: user.userId,
              priority: InsightPriority.LOW,
              category: InsightCategory.GENERAL,
            },
            user.userId,
          );

          generated++;
        } catch (error) {
          errors++;
          this.logger.error(
            `Error generating insights for user ${user.userId}:`,
            error,
          );
        }
      }

      this.logger.log(
        `Daily insight generation completed: ${generated} users processed, ${errors} errors`,
      );
    } catch (error) {
      this.logger.error('Error in daily insight generation:', error);
    }
  }

  /**
   * Clean up expired insights
   * Runs daily at 3 AM
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async cleanupExpiredInsights() {
    this.logger.log('Starting expired insights cleanup...');

    try {
      await this.insightsService.deleteExpiredInsights();
      this.logger.log('Expired insights cleanup completed');
    } catch (error) {
      this.logger.error('Error cleaning up expired insights:', error);
    }
  }

  /**
   * Manually trigger insight generation for a specific user
   */
  async generateInsightsForUser(userId: bigint, elderUserId: bigint) {
    try {
      await this.insightsService.generateInsight(
        {
          insightType: InsightType.MEDICATION_ADHERENCE,
          elderUserId,
          priority: InsightPriority.MEDIUM,
          category: InsightCategory.MEDICATION,
        },
        userId,
      );

      await this.insightsService.generateInsight(
        {
          insightType: InsightType.HEALTH_TREND,
          elderUserId,
          priority: InsightPriority.MEDIUM,
          category: InsightCategory.VITALS,
        },
        userId,
      );

      this.logger.log(
        `Generated insights for user ${userId}, elder ${elderUserId}`,
      );
    } catch (error) {
      this.logger.error(
        `Error generating insights for user ${userId}:`,
        error,
      );
      throw error;
    }
  }
}

