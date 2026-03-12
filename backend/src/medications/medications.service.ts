// @ts-nocheck
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMedicationDto, MedicineFrequency } from './dto/create-medication.dto';
import { UpdateMedicationDto } from './dto/update-medication.dto';
import { LogIntakeDto, IntakeStatus } from './dto/log-intake.dto';
import { ActorContext } from '../common/services/access-control.service';

@Injectable()
export class MedicationsService {
  constructor(private prisma: PrismaService) { }

  /**
   * Convert days array to bitmask (1=Monday, 7=Sunday)
   * Bit 0 = Monday, Bit 6 = Sunday
   */
  private daysToBitmask(days: number[]): number {
    if (!days || days.length === 0) return 127; // All days (1111111)
    let mask = 0;
    for (const day of days) {
      if (day >= 1 && day <= 7) {
        mask |= 1 << (day - 1);
      }
    }
    return mask;
  }

  /**
   * Convert frequency to bitmask
   */
  private frequencyToDaysMask(frequency: MedicineFrequency, periodicDays?: number[]): number {
    switch (frequency) {
      case MedicineFrequency.DAILY:
        return 127; // All days
      case MedicineFrequency.WEEKLY:
        return periodicDays && periodicDays.length > 0 ? this.daysToBitmask(periodicDays) : 1; // Default Monday
      case MedicineFrequency.MONTHLY:
        return 127; // Handled differently but using mask 127 for now
      case MedicineFrequency.PERIODIC:
        return periodicDays && periodicDays.length > 0 ? this.daysToBitmask(periodicDays) : 127;
      case MedicineFrequency.AS_NEEDED:
        return 127;
      default:
        return 127;
    }
  }

  /**
   * Convert reminder times to JSON string for local storage
   */
  private reminderTimesToJson(times: string[]): string {
    return JSON.stringify(times);
  }

  /**
   * Create new medication
   */
  async create(context: ActorContext, createDto: CreateMedicationDto) {
    // Parse strength/dose value if possible
    let doseValueParsed = null;
    if (createDto.strength) {
      const match = String(createDto.strength).match(/(\d+(\.\d+)?)/);
      if (match) doseValueParsed = parseFloat(match[0]);
    }

    const medication = await this.prisma.medication.create({
      data: {
        elderUserId: context.elderUserId,
        medicationName: createDto.name,
        instructions: createDto.dosage,
        notes: createDto.notes || null,
        formCode: createDto.medicineForm || null,
        doseValue: doseValueParsed,
        doseUnitCode:
          createDto.strength && String(createDto.strength).trim() ? 'mg' : null,
        schedules: {
          create: [
            {
              timezone: 'Asia/Karachi',
              startDate: createDto.startDate
                ? new Date(createDto.startDate)
                : new Date(),
              endDate: createDto.endDate ? new Date(createDto.endDate) : null,
              daysMask: this.frequencyToDaysMask(
                createDto.frequency,
                createDto.periodicDays,
              ),
              timesLocal: this.reminderTimesToJson(
                createDto.reminderTimes || [],
              ) as any,
              isPrn: createDto.frequency === MedicineFrequency.AS_NEEDED,
            },
          ],
        },
      } as any,
    });

    return this.mapToResponse(context, medication);
  }

  /**
   * Get all medications for current elder
   */
  async findAll(context: ActorContext) {
    const medications = await this.prisma.medication.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 1, // Get latest schedule
        },
      } as any,
      orderBy: {
        createdAt: 'desc',
      },
    });

    return Promise.all(
      medications.map((medication: any) => this.mapToResponse(context, medication)),
    );
  }

  /**
   * Find one medication by ID
   */
  async findOne(context: ActorContext, medicationId: bigint) {
    const medication = await this.prisma.medication.findFirst({
      where: {
        medicationId,
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          orderBy: {
            createdAt: 'desc',
          },
        },
      } as any,
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    return this.mapToResponse(context, medication);
  }

  /**
   * Update medication
   */
  async update(context: ActorContext, medicationId: bigint, updateDto: UpdateMedicationDto) {
    const medication = await this.prisma.medication.findFirst({
      where: {
        medicationId,
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: true,
      } as any,
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Update medication
    const updateData: any = {};
    if (updateDto.name) updateData.medicationName = updateDto.name;
    if (updateDto.dosage) updateData.instructions = updateDto.dosage;
    if (updateDto.notes !== undefined) updateData.notes = updateDto.notes;

    if (Object.keys(updateData).length > 0) {
      await this.prisma.medication.update({
        where: { medicationId },
        data: updateData,
      });
    }

    // Update or create schedule if frequency or times changed
    if (
      updateDto.reminderTimes ||
      updateDto.frequency ||
      updateDto.startDate !== undefined
    ) {
      const latestSchedule = (medication as any).schedules[0];
      if (latestSchedule) {
        // Update existing schedule
        await this.prisma.medSchedule.update({
          where: { medScheduleId: (latestSchedule as any).medScheduleId },
          data: {
            startDate: updateDto.startDate
              ? new Date(updateDto.startDate)
              : undefined,
            daysMask:
              updateDto.frequency || updateDto.periodicDays
                ? this.frequencyToDaysMask(
                  updateDto.frequency || (medication as any).frequency,
                  updateDto.periodicDays,
                )
                : undefined,
            timesLocal: updateDto.reminderTimes
              ? (this.reminderTimesToJson(updateDto.reminderTimes) as any)
              : undefined,
          },
        });
      }
    }

    const updatedMedication = await this.prisma.medication.findFirst({
      where: { medicationId },
      include: {
        schedules: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      } as any,
    });

    return this.mapToResponse(context, updatedMedication);
  }

  /**
   * Delete medication
   */
  async remove(context: ActorContext, medicationId: bigint) {
    const medication = await this.prisma.medication.findFirst({
      where: {
        medicationId,
        elderUserId: context.elderUserId,
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    await this.prisma.medication.delete({
      where: { medicationId },
    });

    return { success: true };
  }

  /**
   * Log medication intake
   */
  async logIntake(context: ActorContext, logIntakeDto: LogIntakeDto) {
    const medicationId = BigInt(logIntakeDto.medicineId);

    const medication = await this.prisma.medication.findFirst({
      where: {
        medicationId,
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          select: {
            medScheduleId: true,
          },
        },
      } as any,
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Get schedule IDs for this medication
    const scheduleIds = (medication as any).schedules.map((s: any) => s.medScheduleId);

    // Find if an intake record already exists for this time
    const dueAt = new Date(logIntakeDto.scheduledTime);
    const existingIntake = await this.prisma.medIntake.findFirst({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
        dueAt,
      } as any,
    });

    if (existingIntake) {
      // Update existing record
      await this.prisma.medIntake.update({
        where: {
          medIntakeId: existingIntake.medIntakeId,
        },
        data: {
          status: logIntakeDto.status,
          takenAt:
            logIntakeDto.status === IntakeStatus.TAKEN ? new Date() : null,
          remarks: logIntakeDto.remarks,
        },
      });
    } else {
      // Create new intake record
      // Use the latest schedule ID
      const scheduleId = scheduleIds[0];
      await this.prisma.medIntake.create({
        data: {
          medScheduleId: scheduleId,
          dueAt,
          status: logIntakeDto.status,
          takenAt:
            logIntakeDto.status === IntakeStatus.TAKEN ? new Date() : null,
          remarks: logIntakeDto.remarks,
        },
      });
    }

    return { success: true };
  }

  /**
   * Get intake history for a medication
   */
  async getIntakeHistory(context: ActorContext, medicineId: string) {
    const medicationId = BigInt(medicineId);

    const medication = await this.prisma.medication.findFirst({
      where: {
        medicationId,
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          select: {
            medScheduleId: true,
          },
        },
      } as any,
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Get schedule IDs for this medication
    const scheduleIds = (medication as any).schedules.map((s: any) => s.medScheduleId);

    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
      } as any,
      include: {
        schedule: true,
      } as any,
      orderBy: {
        dueAt: 'desc',
      },
      take: 50,
    });

    return intakes.map((intake: any) => ({
      id: intake.medIntakeId.toString(),
      status: intake.status,
      dueAt: intake.dueAt.toISOString(),
      takenAt: intake.takenAt?.toISOString(),
      remarks: intake.remarks,
    }));
  }

  /**
   * Helper to map Prisma medication model to API response
   */
  private async mapToResponse(context: ActorContext, medication: any) {
    const schedules = medication.schedules || [];
    const latestSchedule = schedules[0];

    // Get today's intake for this medication
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const scheduleIds = schedules.map((s: any) => s.medScheduleId);

    const todayIntakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
        dueAt: {
          gte: startOfDay,
          lte: endOfDay,
        },
      } as any,
    });

    const frequency = this.daysMaskToFrequency(
      latestSchedule?.daysMask || 127,
      latestSchedule?.isPrn || false,
    );

    let times = [];
    try {
      if (latestSchedule?.timesLocal) {
        times =
          typeof latestSchedule.timesLocal === 'string'
            ? JSON.parse(latestSchedule.timesLocal)
            : latestSchedule.timesLocal;
      }
    } catch (e) {
      console.error('Error parsing timesLocal:', e);
    }

    return {
      id: medication.medicationId.toString(),
      name: medication.medicationName,
      dosage: medication.instructions || '',
      strength: medication.doseValue ? `${medication.doseValue} mg` : '',
      frequency,
      medicineForm: medication.formCode || 'tablets',
      notes: medication.notes || '',
      reminderTimes: Array.isArray(times) ? times : [],
      startDate: latestSchedule?.startDate?.toISOString(),
      endDate: latestSchedule?.endDate?.toISOString(),
      history: todayIntakes.map((intake: any) => ({
        status: intake.status,
        scheduledTime: intake.dueAt.toISOString(),
        takenTime: intake.takenAt?.toISOString(),
      })),
    };
  }

  /**
   * Convert daysMask back to MedicineFrequency
   */
  private daysMaskToFrequency(mask: number, isPrn: boolean): MedicineFrequency {
    if (isPrn) return MedicineFrequency.AS_NEEDED;
    if (mask === 127) return MedicineFrequency.DAILY;
    // Simple heuristic: if mask is not 127 and not 0, call it periodic
    return MedicineFrequency.PERIODIC;
  }

  /**
   * Calculate adherence for a period
   */
  async calculateAdherence(context: ActorContext, days: number = 7) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const medications = await this.prisma.medication.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          select: {
            medScheduleId: true,
          },
        },
      } as any,
    });

    const allScheduleIds = medications.flatMap((m: any) =>
      m.schedules.map((s: any) => s.medScheduleId),
    );

    if (allScheduleIds.length === 0) {
      return { adherenceRate: 1.0, history: [] };
    }

    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: allScheduleIds,
        },
        dueAt: {
          gte: cutoffDate,
        },
      } as any,
    });

    // Group by date and calculate daily adherence
    const dailyStats = new Map<string, { taken: number; total: number }>();

    intakes.forEach((intake: any) => {
      const dateStr = intake.dueAt.toISOString().split('T')[0];
      const stats = dailyStats.get(dateStr) || { taken: number = 0, total: 0 };
      stats.total++;
      if (intake.status === IntakeStatus.TAKEN) stats.taken++;
      dailyStats.set(dateStr, stats);
    });

    const totalTaken = intakes.filter((i: any) => i.status === IntakeStatus.TAKEN)
      .length;
    const totalIntakes = intakes.length;

    const history = Array.from(dailyStats.entries())
      .map(([date, stats]) => ({
        date,
        adherence: stats.total > 0 ? stats.taken / stats.total : 1.0,
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return {
      adherenceRate: totalIntakes > 0 ? totalTaken / totalIntakes : 1.0,
      history,
    };
  }

  /**
   * Get medication status for a specific date
   */
  async getMedicationStatus(context: ActorContext, targetDate: Date) {
    const dateStart = new Date(targetDate);
    dateStart.setHours(0, 0, 0, 0);

    const dateEnd = new Date(targetDate);
    dateEnd.setHours(23, 59, 59, 999);

    const medications = await this.prisma.medication.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 1,
        },
      } as any,
    });

    let takenCount = 0;
    let missedCount = 0;
    let upcomingCount = 0;
    const medicationStatuses = [];

    for (const medication of medications) {
      if ((medication as any).schedules.length === 0) continue;

      const schedule = (medication as any).schedules[0];
      const times = ((schedule as any).timesLocal as string[]) || [];

      if (!Array.isArray(times) || times.length === 0) continue;

      // Check if medication is active on this date
      if ((schedule as any).startDate > dateEnd) continue;
      if ((schedule as any).endDate && (schedule as any).endDate < dateStart) continue;

      const medicationStatus: any = {
        medicineId: medication.medicationId.toString(),
        name: medication.medicationName,
        scheduledTimes: [],
        status: 'upcoming',
      };

      for (const timeStr of times) {
        const [hours, minutes] = timeStr.split(':').map(Number);
        const scheduledTime = new Date(targetDate);
        scheduledTime.setHours(hours, minutes, 0, 0);

        // Get intake for this scheduled time
        const intake = await this.prisma.medIntake.findFirst({
          where: {
            medScheduleId: (schedule as any).medScheduleId,
            dueAt: scheduledTime,
          },
        } as any);

        let status = 'upcoming';
        if (intake) {
          status = intake.status;
          if (status === IntakeStatus.TAKEN) takenCount++;
          else if (status === IntakeStatus.MISSED) missedCount++;
        } else if (scheduledTime < new Date()) {
          status = 'missed';
          missedCount++;
        } else {
          upcomingCount++;
        }

        medicationStatus.scheduledTimes.push({
          time: timeStr,
          status,
        });
      }

      // Overall status for this medicine today
      if (medicationStatus.scheduledTimes.every((t: any) => t.status === 'taken'))
        medicationStatus.status = 'taken';
      else if (medicationStatus.scheduledTimes.some((t: any) => t.status === 'missed'))
        medicationStatus.status = 'missed';

      medicationStatuses.push(medicationStatus);
    }

    return {
      date: targetDate.toISOString().split('T')[0],
      taken: takenCount,
      missed: missedCount,
      upcoming: upcomingCount,
      medications: medicationStatuses,
    };
  }

  /**
   * Get upcoming reminders
   */
  async getUpcomingReminders(context: ActorContext) {
    const medications = await this.prisma.medication.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 1,
        },
      } as any,
    });

    const reminders: any[] = [];
    const now = new Date();

    for (const medication of medications) {
      if ((medication as any).schedules.length === 0) continue;

      const schedule = (medication as any).schedules[0];
      const times = (schedule as any).timesLocal as string[];

      if (!Array.isArray(times)) continue;

      // Map medication once per medication, not once per reminder time
      const mappedMedicine = await this.mapToResponse(context, medication);

      for (const timeStr of times) {
        const [hours, minutes] = timeStr.split(':').map(Number);
        const reminderTime = new Date(now);
        reminderTime.setHours(hours, minutes, 0, 0);

        if (reminderTime < now) {
          reminderTime.setDate(reminderTime.getDate() + 1);
        }

        reminders.push({
          medicine: mappedMedicine,
          time: timeStr,
          reminderTime: reminderTime.toISOString(),
        });
      }
    }

    return reminders.sort((a, b) => a.reminderTime.localeCompare(b.reminderTime));
  }
}
