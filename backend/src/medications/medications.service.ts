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
   * Convert frequency enum to days mask
   */
  private frequencyToDaysMask(frequency: MedicineFrequency, periodicDays?: number[]): number {
    switch (frequency) {
      case MedicineFrequency.DAILY:
      case MedicineFrequency.TWICE_DAILY:
      case MedicineFrequency.THRICE_DAILY:
      case MedicineFrequency.BEFORE_MEAL:
      case MedicineFrequency.AFTER_MEAL:
        return 127; // All days
      case MedicineFrequency.WEEKLY:
        return 127; // All days (can be adjusted)
      case MedicineFrequency.PERIODIC:
        return this.daysToBitmask(periodicDays || []);
      case MedicineFrequency.AS_NEEDED:
        return 127; // All days
      default:
        return 127;
    }
  }

  /**
   * Convert reminder times to JSONB array
   */
  private reminderTimesToJson(times: { time: string }[]): string[] {
    return times.map((t) => t.time);
  }

  /**
   * Create medication with schedule
   */
  async create(context: ActorContext, createDto: CreateMedicationDto) {
    try {
      const { reminderTimes, frequency, periodicDays, startDate, endDate, ...medicationData } =
        createDto;

      // Parse dose value from strength and doseAmount
      let doseValue: any = null;
      if (medicationData.doseAmount) {
        try {
          // Convert to string if it's not already (handles number input)
          const doseAmountStr = String(medicationData.doseAmount).trim();
          if (doseAmountStr) {
            const match = doseAmountStr.match(/(\d+(?:\.\d+)?)/);
            if (match) {
              doseValue = parseFloat(match[1]);
            }
          }
        } catch (error) {
          // If parsing fails, continue without doseValue
          console.warn('Failed to parse doseAmount:', error);
        }
      }

      // Handle empty strength field - only set unit code if strength is provided and not empty
      const doseUnitCode =
        medicationData.strength && String(medicationData.strength).trim()
          ? 'mg'
          : null;

      // Create medication with schedule
      const medication = await this.prisma.medication.create({
        data: {
          elderUserId: context.elderUserId,
          medicationName: medicationData.name,
          doseValue: doseValue,
          doseUnitCode: doseUnitCode,
          formCode: medicationData.medicineForm || null,
          instructions: medicationData.dosage,
          notes: medicationData.notes || null,
          createdByUserId: context.actorUserId,
          schedules: {
            create: {
              timezone: 'Asia/Karachi',
              startDate: new Date(startDate),
              endDate: endDate ? new Date(endDate) : null,
              daysMask: this.frequencyToDaysMask(frequency, periodicDays),
              timesLocal: this.reminderTimesToJson(reminderTimes) as any,
              isPrn: frequency === MedicineFrequency.AS_NEEDED,
            },
          },
        },
        include: {
          schedules: true,
        },
      });

      return this.mapToResponse(context, medication);
    } catch (error) {
      console.error('Error creating medication:', error);
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(
        `Failed to create medication: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  /**
   * Find all medications for a user
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
      },
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
      },
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
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Update medication
    const updateData: any = {};
    if (updateDto.name) updateData.medicationName = updateDto.name;
    if (updateDto.dosage) updateData.instructions = updateDto.dosage;
    if (updateDto.notes !== undefined) updateData.notes = updateDto.notes;
    if (updateDto.medicineForm) updateData.formCode = updateDto.medicineForm;

    // Parse dose value
    if (updateDto.doseAmount) {
      try {
        // Convert to string if it's not already (handles number input)
        const doseAmountStr = String(updateDto.doseAmount).trim();
        if (doseAmountStr) {
          const match = doseAmountStr.match(/(\d+(?:\.\d+)?)/);
          if (match) {
            updateData.doseValue = parseFloat(match[1]);
          }
        }
      } catch (error) {
        // If parsing fails, continue without doseValue
        console.warn('Failed to parse doseAmount:', error);
      }
    }

    // Handle strength field update - only set unit code if strength is provided and not empty
    if (updateDto.strength !== undefined) {
      updateData.doseUnitCode =
        updateDto.strength && String(updateDto.strength).trim() ? 'mg' : null;
    }

    const updated = await this.prisma.medication.update({
      where: { medicationId },
      data: updateData,
      include: {
        schedules: true,
      },
    });

    // Update or create schedule if schedule data provided
    if (
      updateDto.reminderTimes ||
      updateDto.frequency ||
      updateDto.startDate !== undefined
    ) {
      const latestSchedule = medication.schedules[0];
      if (latestSchedule) {
        // Update existing schedule
        await this.prisma.medSchedule.update({
          where: { medScheduleId: latestSchedule.medScheduleId },
          data: {
            startDate: updateDto.startDate
              ? new Date(updateDto.startDate)
              : latestSchedule.startDate,
            endDate:
              updateDto.endDate !== undefined
                ? updateDto.endDate
                  ? new Date(updateDto.endDate)
                  : null
                : latestSchedule.endDate,
            daysMask:
              updateDto.frequency !== undefined
                ? this.frequencyToDaysMask(updateDto.frequency, updateDto.periodicDays)
                : latestSchedule.daysMask,
            timesLocal:
              updateDto.reminderTimes !== undefined
                ? (this.reminderTimesToJson(updateDto.reminderTimes) as any)
                : latestSchedule.timesLocal,
          },
        });
      } else {
        // Create new schedule
        await this.prisma.medSchedule.create({
          data: {
            medicationId,
            timezone: 'Asia/Karachi',
            startDate: updateDto.startDate ? new Date(updateDto.startDate) : new Date(),
            endDate: updateDto.endDate ? new Date(updateDto.endDate) : null,
            daysMask:
              updateDto.frequency !== undefined
                ? this.frequencyToDaysMask(updateDto.frequency, updateDto.periodicDays)
                : 127,
            timesLocal:
              updateDto.reminderTimes !== undefined
                ? (this.reminderTimesToJson(updateDto.reminderTimes) as any)
                : ([] as any),
            isPrn: updateDto.frequency === MedicineFrequency.AS_NEEDED,
          },
        });
      }
    }

    return this.findOne(context, medicationId);
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

    return { message: 'Medication deleted successfully' };
  }

  /**
   * Get intake history for a medication
   */
  async getIntakeHistory(context: ActorContext, medicationId: bigint) {
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
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Get schedule IDs for this medication
    const scheduleIds = medication.schedules.map((s) => s.medScheduleId);

    if (scheduleIds.length === 0) {
      return [];
    }

    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
      },
      include: {
        schedule: true,
      },
      orderBy: {
        dueAt: 'desc',
      },
    });

    return intakes.map((intake: any) => ({
      id: intake.intakeId.toString(),
      medicationId: medicationId.toString(),
      scheduledTime: intake.dueAt.toISOString(),
      takenTime: intake.takenAt?.toISOString() || null,
      status: intake.status,
    }));
  }

  /**
   * Log medication intake
   */
  async logIntake(
    context: ActorContext,
    medicationId: bigint,
    logDto: LogIntakeDto,
  ) {
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
          take: 1,
        },
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    if (medication.schedules.length === 0) {
      throw new BadRequestException('Medication has no schedule');
    }

    const schedule = medication.schedules[0];
    const dueAt = new Date(logDto.scheduledTime);

    // Check if intake already exists
    const existing = await this.prisma.medIntake.findFirst({
      where: {
        medScheduleId: schedule.medScheduleId,
        dueAt,
      },
    });

    if (existing) {
      // Update existing intake
      const updated = await this.prisma.medIntake.update({
        where: { intakeId: existing.intakeId },
        data: {
          status: logDto.status,
          takenAt: logDto.status === IntakeStatus.TAKEN ? (logDto.takenTime ? new Date(logDto.takenTime) : new Date()) : null,
          notes: logDto.notes || null,
        },
      });

      return {
        id: updated.intakeId.toString(),
        medicationId: medicationId.toString(),
        scheduledTime: updated.dueAt.toISOString(),
        takenTime: updated.takenAt?.toISOString() || null,
        status: updated.status,
      };
    } else {
      // Create new intake
      const intake = await this.prisma.medIntake.create({
        data: {
          medScheduleId: schedule.medScheduleId,
          dueAt,
          status: logDto.status,
          takenAt: logDto.status === IntakeStatus.TAKEN ? (logDto.takenTime ? new Date(logDto.takenTime) : new Date()) : null,
          notes: logDto.notes || null,
          recordedByUserId: context.actorUserId,
        },
      });

      return {
        id: intake.intakeId.toString(),
        medicationId: medicationId.toString(),
        scheduledTime: intake.dueAt.toISOString(),
        takenTime: intake.takenAt?.toISOString() || null,
        status: intake.status,
      };
    }
  }

  /**
   * Get adherence percentage
   */
  async getAdherence(
    context: ActorContext,
    medicationId: bigint,
    days: number = 7,
  ) {
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
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Get schedule IDs for this medication
    const scheduleIds = medication.schedules.map((s) => s.medScheduleId);

    if (scheduleIds.length === 0) {
      return { percentage: 0, total: 0, taken: 0 };
    }

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
        dueAt: {
          gte: cutoffDate,
        },
      },
    });

    if (intakes.length === 0) {
      return { percentage: 0, total: 0, taken: 0 };
    }

    const taken = intakes.filter((intake: any) => intake.status === 'taken').length;
    const percentage = (taken / intakes.length) * 100;

    return {
      percentage: Math.round(percentage * 100) / 100,
      total: intakes.length,
      taken,
    };
  }

  /**
   * Get adherence streak
   */
  async getAdherenceStreak(context: ActorContext, medicationId: bigint) {
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
      },
    });

    if (!medication) {
      throw new NotFoundException('Medication not found');
    }

    // Get schedule IDs for this medication
    const scheduleIds = medication.schedules.map((s) => s.medScheduleId);

    if (scheduleIds.length === 0) {
      return { streak: 0 };
    }

    // Get all intakes ordered by date descending
    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
      },
      orderBy: {
        dueAt: 'desc',
      },
    });

    if (intakes.length === 0) {
      return { streak: 0 };
    }

    // Calculate streak
    // Streak counts consecutive days (going backwards from today) where all scheduled intakes were taken
    let streak = 0;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    for (let i = 0; i < 365; i++) {
      const checkDate = new Date(today);
      checkDate.setDate(checkDate.getDate() - i);

      const dayIntakes = intakes.filter((intake: any) => {
        const intakeDate = new Date(intake.dueAt);
        return (
          intakeDate.getFullYear() === checkDate.getFullYear() &&
          intakeDate.getMonth() === checkDate.getMonth() &&
          intakeDate.getDate() === checkDate.getDate()
        );
      });

      // If no intakes exist for this day
      if (dayIntakes.length === 0) {
        // For today (i === 0), if there are no intakes, streak is 0
        if (i === 0) {
          break;
        }
        // For past days, if we've already started counting a streak, 
        // a day with no intakes breaks the streak
        // Note: This assumes that if intakes exist in the database, they represent
        // all scheduled intakes. Days with no intakes might mean:
        // 1. No intakes were scheduled (e.g., weekend for weekday-only med) - should skip
        // 2. Intakes were scheduled but never logged - breaks streak
        // Since we can't distinguish, we break the streak to be conservative
        if (streak > 0) {
          break;
        }
        // If no streak yet, continue checking older days
        continue;
      }

      // Check if all intakes for this day were taken
      const allTaken = dayIntakes.every((intake: any) => intake.status === 'taken');
      if (allTaken) {
        streak++;
      } else {
        // If not all intakes were taken, break the streak
        // (unless it's today and we haven't started counting yet, which we handle above)
        break;
      }
    }

    return { streak };
  }

  /**
   * Get period-based adherence for all medications
   */
  async getPeriodAdherence(context: ActorContext, days: number = 7) {
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
      },
    });

    if (medications.length === 0) {
      return {
        period: days === 30 ? 'monthly' : 'weekly',
        startDate: new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        endDate: new Date().toISOString().split('T')[0],
        dailyAdherence: [],
        averageAdherence: 100,
      };
    }

    // Get all schedule IDs
    const allScheduleIds = medications.flatMap((m) =>
      m.schedules.map((s) => s.medScheduleId),
    );

    if (allScheduleIds.length === 0) {
      return {
        period: days === 30 ? 'monthly' : 'weekly',
        startDate: new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        endDate: new Date().toISOString().split('T')[0],
        dailyAdherence: [],
        averageAdherence: 100,
      };
    }

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    // Get all intakes for the period
    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: allScheduleIds,
        },
        dueAt: {
          gte: cutoffDate,
        },
      },
    });

    // Group by date and calculate daily adherence
    const dailyAdherence: Array<{ date: string; percentage: number }> = [];
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    for (let i = days - 1; i >= 0; i--) {
      const checkDate = new Date(today);
      checkDate.setDate(checkDate.getDate() - i);

      const dayIntakes = intakes.filter((intake: any) => {
        const intakeDate = new Date(intake.dueAt);
        return (
          intakeDate.getFullYear() === checkDate.getFullYear() &&
          intakeDate.getMonth() === checkDate.getMonth() &&
          intakeDate.getDate() === checkDate.getDate()
        );
      });

      let percentage = 100;
      if (dayIntakes.length > 0) {
        const taken = dayIntakes.filter((intake: any) => intake.status === 'taken').length;
        percentage = Math.round((taken / dayIntakes.length) * 100 * 100) / 100;
      }

      dailyAdherence.push({
        date: checkDate.toISOString().split('T')[0],
        percentage,
      });
    }

    // Calculate average
    const totalPercentage = dailyAdherence.reduce((sum, day) => sum + day.percentage, 0);
    const averageAdherence = dailyAdherence.length > 0
      ? Math.round((totalPercentage / dailyAdherence.length) * 100) / 100
      : 100;

    return {
      period: days === 30 ? 'monthly' : 'weekly',
      startDate: dailyAdherence[0]?.date || new Date().toISOString().split('T')[0],
      endDate: dailyAdherence[dailyAdherence.length - 1]?.date || new Date().toISOString().split('T')[0],
      dailyAdherence,
      averageAdherence,
    };
  }

  /**
   * Get medication status for a specific date
   */
  async getMedicationStatus(context: ActorContext, targetDate: Date) {
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
      },
    });

    const dateStart = new Date(targetDate);
    dateStart.setHours(0, 0, 0, 0);
    const dateEnd = new Date(targetDate);
    dateEnd.setHours(23, 59, 59, 999);

    let takenCount = 0;
    let missedCount = 0;
    let upcomingCount = 0;
    const medicationStatuses: any[] = [];

    const now = new Date();

    for (const medication of medications) {
      if (medication.schedules.length === 0) continue;

      const schedule = medication.schedules[0];
      const times = (schedule.timesLocal as string[]) || [];

      if (!Array.isArray(times) || times.length === 0) continue;

      // Check if medication is active on this date
      if (schedule.startDate > dateEnd) continue;
      if (schedule.endDate && schedule.endDate < dateStart) continue;

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
            medScheduleId: schedule.medScheduleId,
            dueAt: scheduledTime,
          },
        });

        let status = 'upcoming';
        if (scheduledTime < now) {
          if (intake) {
            status = intake.status === 'taken' ? 'taken' : 'missed';
            if (status === 'taken') takenCount++;
            else missedCount++;
          } else {
            status = 'missed';
            missedCount++;
          }
        } else {
          upcomingCount++;
        }

        medicationStatus.scheduledTimes.push({
          time: timeStr,
          status,
        });
      }

      // Determine overall medication status (worst case)
      const allStatuses = medicationStatus.scheduledTimes.map((t: any) => t.status);
      if (allStatuses.includes('missed')) medicationStatus.status = 'missed';
      else if (allStatuses.includes('taken')) medicationStatus.status = 'taken';
      else medicationStatus.status = 'upcoming';

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
      },
    });

    const reminders: any[] = [];
    const now = new Date();

    for (const medication of medications) {
      if (medication.schedules.length === 0) continue;

      const schedule = medication.schedules[0];
      const times = schedule.timesLocal as string[];

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
          reminderTime: reminderTime.toISOString(),
        });
      }
    }

    reminders.sort((a, b) =>
      new Date(a.reminderTime).getTime() - new Date(b.reminderTime).getTime(),
    );

    return reminders.slice(0, 10);
  }

  /**
   * Map database model to API response
   */
  private async mapToResponse(context: ActorContext, medication: any) {
    const schedule = medication.schedules?.[0];
    const timesLocal = (schedule?.timesLocal as string[]) || [];

    // Fetch adherence if we have medicationId
    let adherence = 100;
    try {
      const adherenceData = await this.getAdherence(context, medication.medicationId);
      adherence = adherenceData.percentage;
    } catch (error) {
      console.warn(`Failed to fetch adherence for medication ${medication.medicationId}:`, error);
    }

    return {
      id: medication.medicationId.toString(),
      name: medication.medicationName,
      dosage: medication.instructions || "",
      frequency: this.determineFrequency(schedule),
      startDate: schedule?.startDate?.toISOString() || medication.createdAt.toISOString(),
      endDate: schedule?.endDate?.toISOString() || null,
      reminderTimes: timesLocal.map((time) => ({ time })),
      notes: medication.notes || null,
      userId: medication.elderUserId.toString(),
      medicineForm: medication.formCode || null,
      strength: medication.doseUnitCode || null,
      doseAmount: medication.doseValue
        ? `${medication.doseValue} ${medication.doseUnitCode || ""}`
        : null,
      periodicDays: schedule ? this.bitmaskToDays(schedule.daysMask) : null,
      adherence,
    };
  }

  /**
   * Determine frequency from schedule
   */
  private determineFrequency(schedule: any): MedicineFrequency {
    if (!schedule) return MedicineFrequency.DAILY;
    if (schedule.isPrn) return MedicineFrequency.AS_NEEDED;
    const timesCount = Array.isArray(schedule.timesLocal) ? schedule.timesLocal.length : 0;
    if (timesCount === 1) return MedicineFrequency.DAILY;
    if (timesCount === 2) return MedicineFrequency.TWICE_DAILY;
    if (timesCount === 3) return MedicineFrequency.THRICE_DAILY;
    if (schedule.daysMask !== 127) return MedicineFrequency.PERIODIC;
    return MedicineFrequency.DAILY;
  }

  /**
   * Convert bitmask to days array
   */
  private bitmaskToDays(mask: number): number[] {
    const days: number[] = [];
    for (let i = 0; i < 7; i++) {
      if (mask & (1 << i)) {
        days.push(i + 1);
      }
    }
    return days;
  }
}

