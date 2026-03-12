import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AIHealthAnalystService } from './ai-health-analyst.service';
import { EmbeddingService } from './embedding.service';
import {
  GenerateInsightDto,
  GetInsightsDto,
  InsightType,
  InsightPriority,
} from '../dto/generate-insight.dto';

@Injectable()
export class AIInsightsService {
  private readonly logger = new Logger(AIInsightsService.name);

  constructor(
    private prisma: PrismaService,
    private healthAnalyst: AIHealthAnalystService,
    private embeddingService: EmbeddingService,
  ) {}

  /**
   * Generate and store an AI insight
   */
  async generateInsight(dto: GenerateInsightDto, userId: bigint) {
    // Validate that elderUserId is provided and exists
    // Convert to BigInt if it's a number (JSON parsing gives numbers, not BigInt)
    if (dto.elderUserId == null || dto.elderUserId === undefined) {
      throw new Error(
        'elderUserId is required. Please provide a valid user ID for whom the insight should be generated.',
      );
    }

    // Convert to BigInt if it's a number
    const elderUserId = typeof dto.elderUserId === 'bigint' 
      ? dto.elderUserId 
      : BigInt(dto.elderUserId);
    
    // Validate that elderUserId is not 0 (invalid user ID)
    if (elderUserId === BigInt(0)) {
      throw new Error(
        'elderUserId cannot be 0. Please provide a valid user ID for whom the insight should be generated.',
      );
    }

    // Validate that elder_user_id exists in users table
    const elderUser = await this.prisma.$queryRawUnsafe<Array<{ count: string }>>(
      `SELECT COUNT(*)::text as count FROM users WHERE "userId" = ${elderUserId}::bigint`,
    );
    
    if (
      elderUser.length === 0 ||
      !elderUser[0] ||
      elderUser[0].count === '0'
    ) {
      throw new Error(
        `Elder user with ID ${elderUserId} does not exist in the database. Please provide a valid user ID.`,
      );
    }

    this.logger.log(
      `Generating ${dto.insightType} insight for elder user ID: ${elderUserId} (requested by user ID: ${userId})`,
    );

    let insight: {
      title: string;
      content: string;
      confidence: number;
      recommendations?: any[];
    } | null;

    switch (dto.insightType) {
      case InsightType.MEDICATION_ADHERENCE:
        insight = await this.generateMedicationAdherenceInsight(elderUserId);
        break;
      case InsightType.HEALTH_TREND:
        insight = await this.generateHealthTrendInsight(elderUserId);
        break;
      case InsightType.RECOMMENDATION:
        insight = await this.generateRecommendationInsight(elderUserId);
        break;
      case InsightType.ALERT:
        insight = await this.generateAlertInsight(elderUserId);
        break;
      case InsightType.PATTERN_DETECTION:
        insight = await this.generatePatternInsight(elderUserId);
        break;
      default:
        throw new Error(`Unknown insight type: ${dto.insightType}`);
    }

    if (!insight) {
      throw new Error('No insight generated');
    }

    // Generate embedding for the insight
    const embeddingText = `${insight.title} ${insight.content}`;
    const embedding = await this.embeddingService.generateEmbedding(embeddingText);

    // Store the insight
    const embeddingArray = `[${embedding.join(',')}]`;
    // Use the normalized elderUserId (will always be a valid bigint at this point)
    const elderUserIdValue = elderUserId.toString();
    const result = await this.prisma.$executeRawUnsafe(
      `INSERT INTO ai_insights (
        user_id, elder_user_id, insight_type, title, content,
        confidence, priority, category, recommendations, embedding,
        metadata, generated_at
      ) VALUES (
        $1::bigint, $2::bigint, $3, $4, $5, $6, $7, $8, $9::jsonb, $10::vector, $11::jsonb, NOW()
      ) RETURNING insight_id`,
      userId.toString(),
      elderUserIdValue,
      dto.insightType,
      insight.title,
      insight.content,
      insight.confidence,
      dto.priority || InsightPriority.MEDIUM,
      dto.category || null,
      JSON.stringify(insight.recommendations || []),
      embeddingArray,
      JSON.stringify(dto.metadata || {}),
    );

    return result;
  }

  /**
   * Get insights with filters
   */
  async getInsights(userId: bigint, dto: GetInsightsDto) {
    let query = `
      SELECT 
        insight_id,
        user_id,
        elder_user_id,
        insight_type,
        title,
        content,
        confidence,
        priority,
        category,
        recommendations,
        is_read,
        is_archived,
        generated_at,
        expires_at,
        created_at
      FROM ai_insights
      WHERE user_id = ${userId}::bigint
        AND is_archived = false
    `;

    if (dto.elderUserId) {
      query += ` AND elder_user_id = ${dto.elderUserId}::bigint`;
    }

    if (dto.types && dto.types.length > 0) {
      const types = dto.types.map((t) => `'${t.replace(/'/g, "''")}'`).join(',');
      query += ` AND insight_type IN (${types})`;
    }

    if (dto.priorities && dto.priorities.length > 0) {
      const priorities = dto.priorities.map((p) => `'${p.replace(/'/g, "''")}'`).join(',');
      query += ` AND priority IN (${priorities})`;
    }

    if (dto.categories && dto.categories.length > 0) {
      const categories = dto.categories.map((c) => `'${c.replace(/'/g, "''")}'`).join(',');
      query += ` AND category IN (${categories})`;
    }

    if (dto.isRead !== undefined) {
      query += ` AND is_read = ${dto.isRead}`;
    }

    query += ` ORDER BY generated_at DESC LIMIT ${dto.limit || 20}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => {
      // Parse recommendations - JSONB columns might be strings or already parsed
      let recommendations = [];
      if (r.recommendations) {
        if (typeof r.recommendations === 'string') {
          try {
            recommendations = r.recommendations.trim() 
              ? JSON.parse(r.recommendations) 
              : [];
          } catch (error) {
            this.logger.warn(
              `Failed to parse recommendations for insight ${r.insight_id}: ${error}`,
            );
            recommendations = [];
          }
        } else {
          // Already parsed (JSONB returns as object/array)
          recommendations = r.recommendations;
        }
      }

      return {
        id: r.insight_id.toString(),
        userId: r.user_id.toString(),
        elderUserId: r.elder_user_id?.toString(),
        type: r.insight_type,
        title: r.title,
        content: r.content,
        confidence: r.confidence ? parseFloat(r.confidence) : null,
        priority: r.priority,
        category: r.category,
        recommendations,
        isRead: r.is_read,
        isArchived: r.is_archived,
        generatedAt: r.generated_at,
        expiresAt: r.expires_at,
        createdAt: r.created_at,
      };
    });
  }

  /**
   * Mark insight as read
   */
  async markAsRead(insightId: bigint, userId: bigint) {
    await this.prisma.$executeRawUnsafe(
      `UPDATE ai_insights 
       SET is_read = true, updated_at = NOW() 
       WHERE insight_id = $1::bigint AND user_id = $2::bigint`,
      insightId.toString(),
      userId.toString(),
    );
  }

  /**
   * Archive insight
   */
  async archiveInsight(insightId: bigint, userId: bigint) {
    await this.prisma.$executeRawUnsafe(
      `UPDATE ai_insights 
       SET is_archived = true, updated_at = NOW() 
       WHERE insight_id = $1::bigint AND user_id = $2::bigint`,
      insightId.toString(),
      userId.toString(),
    );
  }

  /**
   * Delete expired insights
   */
  async deleteExpiredInsights() {
    const result = await this.prisma.$executeRawUnsafe(
      `DELETE FROM ai_insights 
       WHERE expires_at IS NOT NULL AND expires_at < NOW()`,
    );
    this.logger.log(`Deleted expired insights`);
    return result;
  }

  // Private methods for generating specific insight types

  private async generateMedicationAdherenceInsight(elderUserId: bigint) {
    const analysis = await this.healthAnalyst.analyzeHealth(elderUserId);
    const adherence = analysis.medicationAdherence.overallPercentage;

    if (adherence < 70) {
      return {
        title: 'Low Medication Adherence Detected',
        content: `Your medication adherence is ${adherence.toFixed(1)}%, which is below the recommended 80%. This may impact treatment effectiveness.`,
        confidence: 85,
        recommendations: analysis.medicationAdherence.recommendations,
      };
    } else if (adherence < 80) {
      return {
        title: 'Medication Adherence Needs Improvement',
        content: `Your medication adherence is ${adherence.toFixed(1)}%. Consider setting reminders to improve consistency.`,
        confidence: 75,
        recommendations: analysis.medicationAdherence.recommendations,
      };
    }

    return {
      title: 'Good Medication Adherence',
      content: `Your medication adherence is ${adherence.toFixed(1)}%. Keep up the good work!`,
      confidence: 90,
      recommendations: [],
    };
  }

  private async generateHealthTrendInsight(elderUserId: bigint) {
    const analysis = await this.healthAnalyst.analyzeHealth(elderUserId);
    const highConcernTrends = analysis.healthTrends.vitals.filter(
      (v) => v.concernLevel === 'high',
    );

    if (highConcernTrends.length > 0) {
      return {
        title: 'Concerning Health Trends Detected',
        content: `We've detected concerning trends in ${highConcernTrends.map((v) => v.type).join(', ')}. Please consult your healthcare provider.`,
        confidence: 80,
        recommendations: analysis.healthTrends.recommendations,
      };
    }

    return {
      title: 'Health Trends Stable',
      content: 'Your health measurements are within normal ranges and showing stable trends.',
      confidence: 85,
      recommendations: [],
    };
  }

  private async generateRecommendationInsight(elderUserId: bigint) {
    const analysis = await this.healthAnalyst.analyzeHealth(elderUserId);
    const allRecommendations = [
      ...analysis.medicationAdherence.recommendations,
      ...analysis.healthTrends.recommendations,
      ...analysis.lifestyleCorrelation.recommendations,
    ];

    if (allRecommendations.length === 0) {
      return {
        title: 'No Recommendations at This Time',
        content: 'Your health data looks good. Continue maintaining your current routine.',
        confidence: 70,
        recommendations: [],
      };
    }

    return {
      title: 'Personalized Health Recommendations',
      content: `Based on your recent health data, we have ${allRecommendations.length} recommendations to help improve your health outcomes.`,
      confidence: 75,
      recommendations: allRecommendations,
    };
  }

  private async generateAlertInsight(elderUserId: bigint) {
    const analysis = await this.healthAnalyst.analyzeHealth(elderUserId);
    const highRiskFactors = analysis.riskFactors.filter(
      (r) => r.severity === 'high',
    );

    if (highRiskFactors.length > 0) {
      return {
        title: 'Health Alert: Action Required',
        content: `We've identified ${highRiskFactors.length} high-priority risk factor(s) that require attention.`,
        confidence: 90,
        recommendations: highRiskFactors.map((r) => r.recommendation),
      };
    }

    return null; // No alert needed
  }

  private async generatePatternInsight(elderUserId: bigint) {
    // This would use more advanced pattern detection
    // For now, return a simple pattern insight
    return {
      title: 'Health Pattern Analysis',
      content: 'We are analyzing your health patterns. Check back soon for personalized insights.',
      confidence: 60,
      recommendations: [],
    };
  }
}

