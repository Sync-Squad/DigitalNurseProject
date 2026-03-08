// @ts-nocheck
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { VectorSearchService } from './vector-search.service';
import { AppConfigService } from '../../config/config.service';

export interface HealthAnalysisResult {
  medicationAdherence: {
    overallPercentage: number;
    trend: 'improving' | 'declining' | 'stable';
    medications: Array<{
      medicationId: string;
      name: string;
      adherence: number;
      missedDoses: number;
    }>;
    recommendations: string[];
  };
  healthTrends: {
    vitals: Array<{
      type: string;
      trend: 'increasing' | 'decreasing' | 'stable';
      averageValue: number;
      concernLevel: 'low' | 'medium' | 'high';
    }>;
    recommendations: string[];
  };
  lifestyleCorrelation: {
    diet: {
      averageCalories: number;
      consistency: number;
    };
    exercise: {
      averageMinutes: number;
      frequency: number;
    };
    recommendations: string[];
  };
  riskFactors: Array<{
    type: string;
    severity: 'low' | 'medium' | 'high';
    description: string;
    recommendation: string;
  }>;
}

@Injectable()
export class AIHealthAnalystService {
  private readonly logger = new Logger(AIHealthAnalystService.name);

  constructor(
    private prisma: PrismaService,
    private vectorSearchService: VectorSearchService,
    private appConfigService: AppConfigService,
  ) {}

  /**
   * Analyze health data for an elder user
   */
  async analyzeHealth(
    elderUserId: bigint,
    startDate?: Date,
    endDate?: Date,
  ): Promise<HealthAnalysisResult> {
    const analysisStart = startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const analysisEnd = endDate || new Date();

    const [medicationAdherence, healthTrends, lifestyleCorrelation, riskFactors] =
      await Promise.all([
        this.analyzeMedicationAdherence(elderUserId, analysisStart, analysisEnd),
        this.analyzeHealthTrends(elderUserId, analysisStart, analysisEnd),
        this.analyzeLifestyleCorrelation(elderUserId, analysisStart, analysisEnd),
        this.identifyRiskFactors(elderUserId, analysisStart, analysisEnd),
      ]);

    return {
      medicationAdherence,
      healthTrends,
      lifestyleCorrelation,
      riskFactors,
    };
  }

  /**
   * Analyze medication adherence
   */
  private async analyzeMedicationAdherence(
    elderUserId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const medications = await this.prisma.medication.findMany({
      where: { elderUserId },
      include: {
        schedules: {
          include: {
            intakes: {
              where: {
                dueAt: {
                  gte: startDate,
                  lte: endDate,
                },
              },
            },
          },
        },
      },
    });

    const medicationResults = medications.map((med) => {
      const allIntakes = med.schedules.flatMap((s) => s.intakes);
      const totalDoses = allIntakes.length;
      const takenDoses = allIntakes.filter((i) => i.status === 'taken').length;
      const adherence = totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 100;
      const missedDoses = totalDoses - takenDoses;

      return {
        medicationId: med.medicationId.toString(),
        name: med.medicationName,
        adherence: Math.round(adherence * 100) / 100,
        missedDoses,
      };
    });

    const overallAdherence =
      medicationResults.length > 0
        ? medicationResults.reduce((sum, m) => sum + m.adherence, 0) /
          medicationResults.length
        : 100;

    // Determine trend (simplified - compare first half vs second half)
    const trend = this.calculateTrend(medicationResults);

    const recommendations: string[] = [];
    if (overallAdherence < 80) {
      recommendations.push('Consider setting medication reminders');
      recommendations.push('Review medication schedule for conflicts');
    }
    if (medicationResults.some((m) => m.adherence < 70)) {
      recommendations.push('Some medications have low adherence - discuss with healthcare provider');
    }

    return {
      overallPercentage: Math.round(overallAdherence * 100) / 100,
      trend,
      medications: medicationResults,
      recommendations,
    };
  }

  /**
   * Analyze health trends from vital measurements
   */
  private async analyzeHealthTrends(
    elderUserId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const vitals = await this.prisma.vitalMeasurement.findMany({
      where: {
        elderUserId,
        recordedAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { recordedAt: 'asc' },
    });

    // Group by kindCode
    const vitalsByType = vitals.reduce((acc, vital) => {
      if (!acc[vital.kindCode]) {
        acc[vital.kindCode] = [];
      }
      acc[vital.kindCode].push(vital);
      return acc;
    }, {} as Record<string, typeof vitals>);

    const trendResults = Object.entries(vitalsByType).map(([type, measurements]) => {
      const values = measurements
        .map((m) => (m.value1 ? Number(m.value1) : parseFloat(m.valueText || '0') || 0))
        .filter((v) => v > 0);

      if (values.length === 0) {
        return null;
      }

      const averageValue =
        values.reduce((sum, v) => sum + v, 0) / values.length;

      // Simple trend calculation: compare first half vs second half
      const midPoint = Math.floor(values.length / 2);
      const firstHalfAvg =
        values.slice(0, midPoint).reduce((sum, v) => sum + v, 0) / midPoint;
      const secondHalfAvg =
        values.slice(midPoint).reduce((sum, v) => sum + v, 0) /
        (values.length - midPoint);

      let trend: 'increasing' | 'decreasing' | 'stable' = 'stable';
      const changePercent = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;
      if (Math.abs(changePercent) > 5) {
        trend = changePercent > 0 ? 'increasing' : 'decreasing';
      }

      // Determine concern level based on type and values
      const concernLevel = this.determineConcernLevel(type, averageValue, trend);

      return {
        type,
        trend,
        averageValue: Math.round(averageValue * 100) / 100,
        concernLevel,
      };
    }).filter((r) => r !== null) as Array<{
      type: string;
      trend: 'increasing' | 'decreasing' | 'stable';
      averageValue: number;
      concernLevel: 'low' | 'medium' | 'high';
    }>;

    const recommendations: string[] = [];
    const highConcern = trendResults.filter((r) => r.concernLevel === 'high');
    if (highConcern.length > 0) {
      recommendations.push(
        `Monitor ${highConcern.map((r) => r.type).join(', ')} closely - consult healthcare provider if trends continue`,
      );
    }

    return {
      vitals: trendResults,
      recommendations,
    };
  }

  /**
   * Analyze lifestyle correlation
   */
  private async analyzeLifestyleCorrelation(
    elderUserId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const [dietLogs, exerciseLogs] = await Promise.all([
      this.prisma.dietLog.findMany({
        where: {
          userId: elderUserId,
          logDate: {
            gte: startDate,
            lte: endDate,
          },
        },
      }),
      this.prisma.exerciseLog.findMany({
        where: {
          userId: elderUserId,
          logDate: {
            gte: startDate,
            lte: endDate,
          },
        },
      }),
    ]);

    const dietCalories = dietLogs
      .map((d) => d.calories || 0)
      .filter((c) => c > 0);
    const averageCalories =
      dietCalories.length > 0
        ? dietCalories.reduce((sum, c) => sum + c, 0) / dietCalories.length
        : 0;

    const exerciseMinutes = exerciseLogs
      .map((e) => e.durationMinutes || 0)
      .filter((m) => m > 0);
    const averageMinutes =
      exerciseMinutes.length > 0
        ? exerciseMinutes.reduce((sum, m) => sum + m, 0) / exerciseMinutes.length
        : 0;

    const recommendations: string[] = [];
    if (averageCalories === 0) {
      recommendations.push('Start logging meals to track nutrition');
    }
    if (averageMinutes < 150) {
      recommendations.push('Aim for at least 150 minutes of exercise per week');
    }

    return {
      diet: {
        averageCalories: Math.round(averageCalories),
        consistency: dietLogs.length,
      },
      exercise: {
        averageMinutes: Math.round(averageMinutes),
        frequency: exerciseLogs.length,
      },
      recommendations,
    };
  }

  /**
   * Identify risk factors
   */
  private async identifyRiskFactors(
    elderUserId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const riskFactors: Array<{
      type: string;
      severity: 'low' | 'medium' | 'high';
      description: string;
      recommendation: string;
    }> = [];

    // Check for missed medications
    const medications = await this.prisma.medication.findMany({
      where: { elderUserId },
      include: {
        schedules: {
          include: {
            intakes: {
              where: {
                dueAt: { gte: startDate, lte: endDate },
                status: { not: 'taken' },
              },
            },
          },
        },
      },
    });

    const totalMissed = medications.reduce(
      (sum, m) =>
        sum + m.schedules.reduce((s, sch) => s + sch.intakes.length, 0),
      0,
    );

    if (totalMissed > 10) {
      riskFactors.push({
        type: 'medication_adherence',
        severity: 'high',
        description: `High number of missed medications (${totalMissed} doses)`,
        recommendation: 'Review medication schedule and consider reminder system',
      });
    }

    // Check for concerning vital trends
    const vitals = await this.prisma.vitalMeasurement.findMany({
      where: {
        elderUserId,
        recordedAt: { gte: startDate, lte: endDate },
      },
    });

    const bpReadings = vitals
      .filter((v) => v.kindCode === 'bp')
      .map((v) => ({ systolic: v.value1, diastolic: v.value2 }))
      .filter((v) => v.systolic && v.diastolic);

    if (bpReadings.length > 0) {
      const avgSystolic =
        bpReadings.reduce((sum, v) => sum + Number(v.systolic || 0), 0) /
        bpReadings.length;
      if (avgSystolic > 140) {
        riskFactors.push({
          type: 'blood_pressure',
          severity: 'medium',
          description: 'Elevated blood pressure readings detected',
          recommendation: 'Monitor blood pressure regularly and consult healthcare provider',
        });
      }
    }

    return riskFactors;
  }

  private calculateTrend(
    medications: Array<{ adherence: number }>,
  ): 'improving' | 'declining' | 'stable' {
    // Simplified trend calculation
    const avgAdherence =
      medications.reduce((sum, m) => sum + m.adherence, 0) / medications.length;
    if (avgAdherence >= 90) return 'stable';
    if (avgAdherence >= 75) return 'improving';
    return 'declining';
  }

  private determineConcernLevel(
    type: string,
    value: number,
    trend: 'increasing' | 'decreasing' | 'stable',
  ): 'low' | 'medium' | 'high' {
    // Simplified concern level determination
    // This should be customized based on medical guidelines
    if (type === 'bp') {
      if (value > 140) return 'high';
      if (value > 130) return 'medium';
    }
    if (type === 'bs') {
      if (value > 180) return 'high';
      if (value > 140) return 'medium';
    }
    if (trend === 'increasing' && type === 'weight') return 'medium';
    return 'low';
  }
}
