import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVitalDto, VitalType } from './dto/create-vital.dto';
import { UpdateVitalDto } from './dto/update-vital.dto';
import { ActorContext } from '../common/services/access-control.service';
import { getPKTDate } from '../common/utils/date-utils';

@Injectable()
export class VitalsService {
  constructor(private prisma: PrismaService) { }

  /**
   * Map app enum to database kindCode
   */
  private typeToKindCode(type: VitalType): string {
    const mapping: Record<VitalType, string> = {
      [VitalType.BLOOD_PRESSURE]: 'bp',
      [VitalType.BLOOD_SUGAR]: 'bs',
      [VitalType.HEART_RATE]: 'hr',
      [VitalType.TEMPERATURE]: 'temp',
      [VitalType.OXYGEN_SATURATION]: 'o2',
      [VitalType.WEIGHT]: 'weight',
    };
    return mapping[type] || type.toLowerCase();
  }

  /**
   * Map database kindCode to app enum
   */
  private kindCodeToType(kindCode: string): VitalType {
    const mapping: Record<string, VitalType> = {
      bp: VitalType.BLOOD_PRESSURE,
      bs: VitalType.BLOOD_SUGAR,
      hr: VitalType.HEART_RATE,
      temp: VitalType.TEMPERATURE,
      o2: VitalType.OXYGEN_SATURATION,
      weight: VitalType.WEIGHT,
    };
    return mapping[kindCode.toLowerCase()] || (kindCode as VitalType);
  }

  /**
   * Parse value string to value1/value2/valueText
   */
  private parseValue(type: VitalType, value: string): {
    value1: number | null;
    value2: number | null;
    valueText: string | null;
  } {
    if (type === VitalType.BLOOD_PRESSURE) {
      const parts = value.split('/');
      if (parts.length === 2) {
        return {
          value1: parseFloat(parts[0]) || null,
          value2: parseFloat(parts[1]) || null,
          valueText: null,
        };
      }
    }

    // For other types, try to parse as number
    const numValue = parseFloat(value);
    if (!isNaN(numValue)) {
      return {
        value1: numValue,
        value2: null,
        valueText: null,
      };
    }

    // If not a number, store as text
    return {
      value1: null,
      value2: null,
      valueText: value,
    };
  }

  /**
   * Format value1/value2/valueText to string
   */
  private formatValue(measurement: any): string {
    if (measurement.valueText) {
      return measurement.valueText;
    }

    if (measurement.value1 !== null && measurement.value2 !== null) {
      return `${measurement.value1}/${measurement.value2}`;
    }

    if (measurement.value1 !== null) {
      return measurement.value1.toString();
    }

    return '';
  }

  /**
   * Create vital measurement
   */
  async create(context: ActorContext, createDto: CreateVitalDto) {
    try {
      const { type, value, timestamp, notes } = createDto;

      // Ensure value is a string for parsing
      const valueStr = typeof value === 'string' ? value : String(value);
      const { value1, value2, valueText } = this.parseValue(type, valueStr);

      const measurement = await this.prisma.vitalMeasurement.create({
        data: {
          elderUserId: context.elderUserId,
          kindCode: this.typeToKindCode(type),
          unitCode: this.getUnitCode(type),
          value1: value1,
          value2: value2,
          valueText: valueText,
          recordedAt: getPKTDate(timestamp),
          source: 'manual',
          notes: notes || null,
          recordedByUserId: context.actorUserId,
          createdAt: getPKTDate(),
          updatedAt: getPKTDate(),
        },
      });

      return this.mapToResponse(measurement);
    } catch (error) {
      console.error('Error in VitalsService.create:', error);
      console.error('Context:', context);
      console.error('DTO:', createDto);
      throw error;
    }
  }

  /**
   * Find all vitals for a user
   */
  async findAll(
    context: ActorContext,
    type?: VitalType,
    startDate?: Date,
    endDate?: Date,
  ) {
    const where: any = {
      elderUserId: context.elderUserId,
    };

    if (type) {
      where.kindCode = this.typeToKindCode(type);
    }

    if (startDate || endDate) {
      where.recordedAt = {};
      if (startDate) where.recordedAt.gte = startDate;
      if (endDate) where.recordedAt.lte = endDate;
    }

    const measurements = await this.prisma.vitalMeasurement.findMany({
      where,
      orderBy: {
        recordedAt: 'desc',
      },
    });

    return measurements.map((m) => this.mapToResponse(m));
  }

  /**
   * Get recent vitals with a limit
   */
  async getRecent(
    context: ActorContext,
    limit: number = 10,
    type?: VitalType,
  ) {
    const where: any = {
      elderUserId: context.elderUserId,
    };

    if (type) {
      where.kindCode = this.typeToKindCode(type);
    }

    const measurements = await this.prisma.vitalMeasurement.findMany({
      where,
      orderBy: {
        recordedAt: 'desc',
      },
      take: limit,
    });

    return measurements.map((m) => this.mapToResponse(m));
  }

  /**
   * Find one vital by ID

   */
  async findOne(context: ActorContext, vitalId: bigint) {
    const measurement = await this.prisma.vitalMeasurement.findFirst({
      where: {
        vitalMeasurementId: vitalId,
        elderUserId: context.elderUserId,
      },
    });

    if (!measurement) {
      throw new NotFoundException('Vital measurement not found');
    }

    return this.mapToResponse(measurement);
  }

  /**
   * Update vital measurement
   */
  async update(context: ActorContext, vitalId: bigint, updateDto: UpdateVitalDto) {
    const measurement = await this.prisma.vitalMeasurement.findFirst({
      where: {
        vitalMeasurementId: vitalId,
        elderUserId: context.elderUserId,
      },
    });

    if (!measurement) {
      throw new NotFoundException('Vital measurement not found');
    }

    const updateData: any = {};

    if (updateDto.type !== undefined) {
      updateData.kindCode = this.typeToKindCode(updateDto.type);
      updateData.unitCode = this.getUnitCode(updateDto.type);
    }

    if (updateDto.value !== undefined) {
      const type = updateDto.type || this.kindCodeToType(measurement.kindCode);
      const parsed = this.parseValue(type, updateDto.value);
      updateData.value1 = parsed.value1;
      updateData.value2 = parsed.value2;
      updateData.valueText = parsed.valueText;
    }

    if (updateDto.timestamp !== undefined) {
      updateData.recordedAt = new Date(updateDto.timestamp);
    }

    if (updateDto.notes !== undefined) {
      updateData.notes = updateDto.notes;
    }

    const updated = await this.prisma.vitalMeasurement.update({
      where: { vitalMeasurementId: vitalId },
      data: updateData,
    });

    return this.mapToResponse(updated);
  }

  /**
   * Delete vital measurement
   */
  async remove(context: ActorContext, vitalId: bigint) {
    const measurement = await this.prisma.vitalMeasurement.findFirst({
      where: {
        vitalMeasurementId: vitalId,
        elderUserId: context.elderUserId,
      },
    });

    if (!measurement) {
      throw new NotFoundException('Vital measurement not found');
    }

    await this.prisma.vitalMeasurement.delete({
      where: { vitalMeasurementId: vitalId },
    });

    return { message: 'Vital measurement deleted successfully' };
  }

  /**
   * Get latest vitals per kind (use database view)
   */
  async getLatest(context: ActorContext) {
    // Use raw query to access the view
    const results = await this.prisma.$queryRaw`
      SELECT * FROM "v_vitals_latest_per_kind"
      WHERE "elderUserId" = ${context.elderUserId}
    `;

    return (results as any[]).map((r) => this.mapToResponse(r));
  }

  /**
   * Get trends for vital measurements
   */
  async getTrends(context: ActorContext, kindCode?: string, days: number = 7) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const where: any = {
      elderUserId: context.elderUserId,
      recordedAt: {
        gte: cutoffDate,
      },
    };

    if (kindCode) {
      where.kindCode = kindCode;
    }

    const measurements = await this.prisma.vitalMeasurement.findMany({
      where,
      orderBy: {
        recordedAt: 'asc',
      },
    });

    if (measurements.length === 0) {
      return kindCode
        ? [
          {
            kindCode,
            average: 0,
            count: 0,
            hasAbnormal: false,
            measurements: [],
          },
        ]
        : [];
    }

    // Group by kindCode
    const grouped = new Map<string, any[]>();
    for (const m of measurements) {
      if (!grouped.has(m.kindCode)) {
        grouped.set(m.kindCode, []);
      }
      grouped.get(m.kindCode)!.push(m);
    }

    const results: any[] = [];

    for (const [code, vitals] of grouped.entries()) {
      // Calculate average (handle different value types)
      let sum = 0;
      let count = 0;
      const hasAbnormal = vitals.some((v) => this.isAbnormal(v));

      for (const vital of vitals) {
        if (vital.value1 !== null) {
          sum += parseFloat(vital.value1.toString());
          count++;
        } else if (vital.valueText) {
          // For blood pressure, parse "120/80" format
          const parts = vital.valueText.split('/');
          if (parts.length === 2) {
            const systolic = parseFloat(parts[0]);
            if (!isNaN(systolic)) {
              sum += systolic;
              count++;
            }
          }
        }
      }

      const average = count > 0 ? sum / count : 0;

      results.push({
        kindCode: code,
        average: Math.round(average * 100) / 100,
        count: vitals.length,
        hasAbnormal,
        measurements: vitals.map((v) => this.mapToResponse(v)),
      });
    }

    return results;
  }

  /**
   * Get abnormal readings
   */
  async getAbnormal(context: ActorContext) {
    const measurements = await this.prisma.vitalMeasurement.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      orderBy: {
        recordedAt: 'desc',
      },
    });

    return measurements
      .filter((m) => this.isAbnormal(m))
      .map((m) => this.mapToResponse(m));
  }

  /**
   * Check if a reading is abnormal
   */
  private isAbnormal(measurement: any): boolean {
    const kindCode = measurement.kindCode.toLowerCase();
    const value1 = measurement.value1 ? parseFloat(measurement.value1.toString()) : null;
    const value2 = measurement.value2 ? parseFloat(measurement.value2.toString()) : null;

    if (kindCode === 'bp' && value1 && value2) {
      // Blood pressure: >140/90 or <80/50
      return value1 > 140 || value1 < 80 || value2 > 90 || value2 < 50;
    }

    if (kindCode === 'bs' && value1 !== null) {
      // Blood sugar: >125 or <60
      return value1 > 125 || value1 < 60;
    }

    if (kindCode === 'hr' && value1 !== null) {
      // Heart rate: <50 or >110
      return value1 < 50 || value1 > 110;
    }

    if (kindCode === 'temp' && value1 !== null) {
      // Temperature: <96.0 or >100.4
      return value1 < 96.0 || value1 > 100.4;
    }

    if (kindCode === 'o2' && value1 !== null) {
      // Oxygen saturation: <90
      return value1 < 90;
    }

    return false;
  }

  /**
   * Get unit code for vital type
   */
  private getUnitCode(type: VitalType): string {
    const mapping: Record<VitalType, string> = {
      [VitalType.BLOOD_PRESSURE]: 'mmHg',
      [VitalType.BLOOD_SUGAR]: 'mg/dL',
      [VitalType.HEART_RATE]: 'bpm',
      [VitalType.TEMPERATURE]: '°F',
      [VitalType.OXYGEN_SATURATION]: '%',
      [VitalType.WEIGHT]: 'lbs',
    };
    return mapping[type] || '';
  }

  /**
   * Map database model to API response
   */
  private mapToResponse(measurement: any) {
    return {
      id: measurement.vitalMeasurementId.toString(),
      type: this.kindCodeToType(measurement.kindCode),
      value: this.formatValue(measurement),
      timestamp: measurement.recordedAt.toISOString(),
      notes: measurement.notes || null,
      userId: measurement.elderUserId.toString(),
      value1: measurement.value1,
      value2: measurement.value2,
      status: this.getStatus(measurement),
    };
  }

  /**
   * Get clinical status for a measurement
   */
  private getStatus(measurement: any): string {
    const kindCode = measurement.kindCode.toLowerCase();
    const v1 = measurement.value1 ? parseFloat(measurement.value1.toString()) : null;
    const v2 = measurement.value2 ? parseFloat(measurement.value2.toString()) : null;

    if (kindCode === "bp" && v1 && v2) {
      if (v1 > 140 || v2 > 90) return "High";
      if (v1 < 90 || v2 < 60) return "Low";
      return "In range";
    }
    if (kindCode === "hr" && v1) {
      if (v1 > 100) return "High";
      if (v1 < 60) return "Low";
      return "In range";
    }
    if (kindCode === "bs" && v1) {
      if (v1 > 140) return "High";
      if (v1 < 70) return "Low";
      return "In range";
    }
    if (kindCode === "o2" && v1) {
      if (v1 < 95) return "Low";
      return "In range";
    }
    if (kindCode === "temp" && v1) {
      if (v1 > 100.4) return "High";
      if (v1 < 97) return "Low";
      return "In range";
    }

    return "Stable";
  }
}

