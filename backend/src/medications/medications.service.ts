// @ts-nocheck
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMedicationDto, MedicineFrequency } from './dto/create-medication.dto';
import { UpdateMedicationDto } from './dto/update-medication.dto';
import { LogIntakeDto, IntakeStatus } from './dto/log-intake.dto';
import { ActorContext } from '../common/services/access-control.service';
import { getPKTDate, getUTCFromPKT, getPKTDateOnly } from '../common/utils/date-utils';

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
   * Process reminder times for storage
   */
  private processReminderTimes(times: any[]): any[] {
    if (!Array.isArray(times)) return [];
    return times.map((t) =>
      typeof t === 'object' && t !== null && 'time' in t ? t.time : t,
    );
  }

  /**
   * Create new medication
   */
  async create(context: ActorContext, createDto: CreateMedicationDto) {
    // Parse numerical value and unit for storage
    // Priority 1: Strength (e.g., "500mg" -> 500, "mg")
    // Priority 2: Dose Amount (e.g., "1 tablet" -> 1, "tablet")
    let doseValueParsed = null;
    let doseUnit = null;

    if (createDto.strength) {
      const match = String(createDto.strength).match(/(\d+(\.\d+)?)\s*([a-zA-Z%]+.*)/);
      if (match) {
        doseValueParsed = parseFloat(match[1]);
        doseUnit = match[3].trim() || null;
      } else {
        const numericMatch = String(createDto.strength).match(/(\d+(\.\d+)?)/);
        if (numericMatch) doseValueParsed = parseFloat(numericMatch[0]);
      }
    }

    if (!doseValueParsed && createDto.doseAmount) {
      const match = String(createDto.doseAmount).match(/(\d+(\.\d+)?)\s*(.*)/);
      if (match) {
        doseValueParsed = parseFloat(match[1]);
        if (!doseUnit) doseUnit = match[3].trim() || null;
      }
    }

    // Ensure we at least have a unit if numeric part is missing but strength is just a unit (e.g. "mg")
    if (!doseUnit && createDto.strength && /^[a-zA-Z%]+$/.test(String(createDto.strength).trim())) {
      doseUnit = String(createDto.strength).trim();
    }

    const medication = await this.prisma.medication.create({
      data: {
        elderUserId: context.elderUserId,
        medicationName: createDto.name,
        instructions: createDto.dosage,
        notes: createDto.notes || null,
        priority: createDto.priority || 'medium',
        formCode: createDto.medicineForm || null,
        doseValue: doseValueParsed,
        doseUnitCode: doseUnit,
        createdAt: getPKTDate(),
        updatedAt: getPKTDate(),
        schedules: {
          create: [
            {
              timezone: 'Asia/Karachi',
              startDate: createDto.startDate
                ? getPKTDate(createDto.startDate)
                : getPKTDate(),
              endDate: createDto.endDate ? getPKTDate(createDto.endDate) : null,
              daysMask: this.frequencyToDaysMask(
                createDto.frequency,
                createDto.periodicDays,
              ),
              timesLocal: this.processReminderTimes(
                createDto.reminderTimes || [],
              ),
              isPrn: createDto.frequency === MedicineFrequency.AS_NEEDED,
              createdAt: getPKTDate(),
              updatedAt: getPKTDate(),
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

    // Update medication fields
    const updateData: any = {};
    if (updateDto.name) updateData.medicationName = updateDto.name;
    if (updateDto.dosage) updateData.instructions = updateDto.dosage;
    if (updateDto.notes !== undefined) updateData.notes = updateDto.notes;
    if (updateDto.priority) updateData.priority = updateDto.priority;
    if (updateDto.medicineForm) updateData.formCode = updateDto.medicineForm;

    // Parse numerical value and unit for update
    let updatedDoseValue = null;
    let updatedDoseUnit = null;

    if (updateDto.strength) {
      const match = String(updateDto.strength).match(/(\d+(\.\d+)?)\s*([a-zA-Z%]+.*)/);
      if (match) {
        updatedDoseValue = parseFloat(match[1]);
        updatedDoseUnit = match[3].trim() || null;
      } else {
        const numericMatch = String(updateDto.strength).match(/(\d+(\.\d+)?)/);
        if (numericMatch) updatedDoseValue = parseFloat(numericMatch[0]);
      }
    }

    if (!updatedDoseValue && updateDto.doseAmount) {
      const match = String(updateDto.doseAmount).match(/(\d+(\.\d+)?)\s*(.*)/);
      if (match) {
        updatedDoseValue = parseFloat(match[1]);
        if (!updatedDoseUnit) updatedDoseUnit = match[3].trim() || null;
      }
    }

    // Ensure we at least have a unit if numeric part is missing but strength is just a unit
    if (!updatedDoseUnit && updateDto.strength && /^[a-zA-Z%]+$/.test(String(updateDto.strength).trim())) {
      updatedDoseUnit = String(updateDto.strength).trim();
    }

    if (updatedDoseValue !== null) updateData.doseValue = updatedDoseValue;
    if (updatedDoseUnit !== null) updateData.doseUnitCode = updatedDoseUnit;
    
    updateData.updatedAt = getPKTDate();

    if (Object.keys(updateData).length > 0) {
      await this.prisma.medication.update({
        where: { medicationId },
        data: updateData,
      });
    }

    // Update or create schedule if frequency, times or dates changed
    if (
      updateDto.reminderTimes ||
      updateDto.frequency ||
      updateDto.startDate !== undefined ||
      updateDto.endDate !== undefined
    ) {
      const latestSchedule = (medication as any).schedules[0];
      if (latestSchedule) {
        // Update existing schedule
        await this.prisma.medSchedule.update({
          where: { medScheduleId: (latestSchedule as any).medScheduleId },
          data: {
            startDate: updateDto.startDate
              ? getPKTDate(updateDto.startDate)
              : undefined,
            endDate: updateDto.endDate !== undefined
              ? (updateDto.endDate ? getPKTDate(updateDto.endDate) : null)
              : undefined,
            daysMask:
              updateDto.frequency || updateDto.periodicDays
                ? this.frequencyToDaysMask(
                  updateDto.frequency || (medication as any).frequency,
                  updateDto.periodicDays,
                )
                : undefined,
            timesLocal: updateDto.reminderTimes
              ? this.processReminderTimes(updateDto.reminderTimes)
              : undefined,
            updatedAt: getPKTDate(),
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
  async logIntake(context: ActorContext, medicationId: bigint, logIntakeDto: LogIntakeDto) {

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
    const dueAt = getPKTDate(logIntakeDto.scheduledTime);
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
            logIntakeDto.status === IntakeStatus.TAKEN
              ? logIntakeDto.takenTime
                ? getPKTDate(logIntakeDto.takenTime)
                : getPKTDate()
              : null,
          remarks: logIntakeDto.notes,
          skipReasonCode: logIntakeDto.skipReasonCode,
          updatedAt: getPKTDate(),
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
            logIntakeDto.status === IntakeStatus.TAKEN
              ? logIntakeDto.takenTime
                ? getPKTDate(logIntakeDto.takenTime)
                : getPKTDate()
              : null,
          remarks: logIntakeDto.notes,
          skipReasonCode: logIntakeDto.skipReasonCode,
          createdAt: getPKTDate(),
          updatedAt: getPKTDate(),
        },
      });
    }

    return { success: true };
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
      medicineId: medication.medicationId.toString(),
      medicineName: medication.medicationName,
      status: intake.status,
      scheduledTime: intake.dueAt.toISOString(),
      takenTime: intake.takenAt?.toISOString(),
      remarks: intake.remarks,
      skipReasonCode: intake.skipReasonCode,
    }));
  }

  /**
   * Get all intake records for all medications of a user
   */
  async findAllIntakes(context: ActorContext) {
    const medications = await this.prisma.medication.findMany({
      where: {
        elderUserId: context.elderUserId,
      },
      include: {
        schedules: true,
      } as any,
    });

    const scheduleIds = medications.flatMap((m: any) => 
      m.schedules.map((s: any) => s.medScheduleId)
    );

    const intakes = await this.prisma.medIntake.findMany({
      where: {
        medScheduleId: {
          in: scheduleIds,
        },
      } as any,
      include: {
        schedule: {
          include: {
            medication: true,
          },
        },
      } as any,
      orderBy: {
        dueAt: 'desc',
      },
      take: 100, // Limit to recent history for performance
    });

    return intakes.map((intake: any) => ({
      id: intake.medIntakeId.toString(),
      medicineId: intake.schedule.medicationId.toString(),
      medicineName: intake.schedule.medication.medicationName,
      status: intake.status,
      scheduledTime: intake.dueAt.toISOString(),
      takenTime: intake.takenAt?.toISOString(),
      remarks: intake.remarks,
      skipReasonCode: intake.skipReasonCode,
    }));
  }

  /**
   * Helper to map Prisma medication model to API response
   */
  private async mapToResponse(context: ActorContext, medication: any) {
    const schedules = medication.schedules || [];
    const latestSchedule = schedules[0];

    // Get today's intake for this medication
    const startOfDay = getPKTDate();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = getPKTDate();
    endOfDay.setHours(23, 59, 59, 999);

    const scheduleIds = (schedules as any[]).map((s: any) => s.medScheduleId);
    if (scheduleIds.length === 0) {
      return {
        id: medication.medicationId.toString(),
        name: medication.medicationName,
        dosage: medication.instructions || '',
        strength: medication.doseValue ? `${medication.doseValue} mg` : '',
        doseAmount: medication.doseValue ? `${medication.doseValue} ${medication.doseUnitCode || ''}`.trim() : '',
        frequency: this.daysMaskToFrequency(127, false),
        medicineForm: medication.formCode || 'tablets',
        notes: medication.notes || '',
        priority: medication.priority || 'medium',
        reminderTimes: [],
        startDate: null,
        endDate: null,
        history: [],
      };
    }

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

    // Try to derive doseAmount and strength from instructions
    let doseAmountStr = '';
    let strengthStr = '';
    const instr = medication.instructions || '';
    if (instr.includes(' of ')) {
      const parts = instr.split(' of ');
      doseAmountStr = parts[0];
      strengthStr = parts[1];
    } else {
      // Fallback: use doseValue and doseUnitCode for doseAmount
      if (medication.doseValue) {
        doseAmountStr = `${medication.doseValue} ${medication.doseUnitCode || ''}`.trim();
      }
      // Strength remains empty or from instructions if no ' of '
      strengthStr = instr;
    }

    return {
      id: medication.medicationId.toString(),
      name: medication.medicationName,
      dosage: instr,
      strength: strengthStr,
      doseAmount: doseAmountStr,
      frequency,
      medicineForm: medication.formCode || 'tablets',
      notes: medication.notes || '',
      priority: medication.priority || 'medium',
      reminderTimes: Array.isArray(times) ? times : [],
      startDate: latestSchedule?.startDate?.toISOString(),
      endDate: latestSchedule?.endDate?.toISOString(),
      history: todayIntakes.map((intake: any) => ({
        id: intake.medIntakeId.toString(),
        medicineId: medication.medicationId.toString(),
        medicineName: medication.medicationName,
        status: intake.status,
        scheduledTime: intake.dueAt.toISOString(),
        takenTime: intake.takenAt?.toISOString(),
        remarks: intake.remarks,
        skipReasonCode: intake.skipReasonCode,
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

  private getNowPKT(): Date {
    const now = new Date();
    try {
      // Robust way to get PKT regardless of server timezone
      const karachiTime = now.toLocaleString('en-US', { timeZone: 'Asia/Karachi' });
      return new Date(karachiTime);
    } catch (e) {
      // Fallback if environment doesn't support IANA timezones (unlikely in modern Node)
      // Pakistan is UTC+5
      const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
      return new Date(utc + (3600000 * 5));
    }
  }

  /**
   * Helper to check if a medication is scheduled for a specific date
   */
  private isScheduledOnDate(schedule: any, date: Date): boolean {
    // Normalize date to midnight in PKT context for comparison
    // Karachi is UTC+5
    const pktDate = new Date(date.getTime() + (5 * 60 * 60 * 1000));
    const checkDate = new Date(pktDate);
    checkDate.setUTCHours(0, 0, 0, 0);

    const start = new Date(schedule.startDate);
    start.setHours(0, 0, 0, 0); // Start date is already stored as midnight
    
    // Convert current check date back to "Calendar Date" for comparison with start/end
    const calendarDate = new Date(pktDate.getUTCFullYear(), pktDate.getUTCMonth(), pktDate.getUTCDate());
    
    if (calendarDate < start) return false;

    if (schedule.endDate) {
      const end = new Date(schedule.endDate);
      end.setHours(23, 59, 59, 999);
      if (calendarDate > end) return false;
    }

    // 2. Check daysMask (Bit 0 = Monday, ..., Bit 6 = Sunday)
    const day = pktDate.getUTCDay(); // 0-6 (Sun-Sat) in PKT
    const shiftedDay = day === 0 ? 6 : day - 1; // 0=Mon, ..., 6=Sun
    return (schedule.daysMask & (1 << shiftedDay)) !== 0;
  }

  /**
   * Calculate adherence for a period
   */
  async calculateAdherence(context: ActorContext, days: number = 7) {
    console.log(`DEBUG [ADHERENCE] Calculating for ${days} days. User: ${context.elderUserId}`);
    const now = new Date(); // Current UTC time
    
    // Get start date in PKT midnight
    const pktNow = new Date(now.getTime() + (5 * 60 * 60 * 1000));
    const startDatePkt = new Date(pktNow);
    startDatePkt.setUTCHours(0, 0, 0, 0);
    startDatePkt.setUTCDate(startDatePkt.getUTCDate() - days + 1);
    
    // Convert back to UTC for DB queries
    const startDateUtc = new Date(startDatePkt.getTime() - (5 * 60 * 60 * 1000));

    const medications = await this.prisma.medication.findMany({
      where: { elderUserId: context.elderUserId },
      include: {
        schedules: {
          orderBy: { createdAt: 'desc' },
          take: 1
        }
      } as any,
    });

    let totalScheduledDoses = 0;
    let totalTakenDoses = 0;
    const dailyAdherence: { [key: string]: { taken: number; total: number } } = {};

    for (const med of medications) {
      if (!med.schedules?.[0]) continue;
      const schedule = med.schedules[0];
      let times = schedule.timesLocal || [];
      if (typeof times === 'string') {
        try {
          times = JSON.parse(times);
        } catch (e) {
          times = [];
        }
      }

      // Get all intakes for this medication in the period
      const intakes = await this.prisma.medIntake.findMany({
        where: {
          medScheduleId: schedule.medScheduleId,
          dueAt: { gte: startDateUtc, lte: now }
        } as any
      });

      const intakeMap = new Map(
        intakes.map((i: any) => [i.dueAt.toISOString(), i.status])
      );

      // Iterate through each day in the period
      for (let i = 0; i < days; i++) {
        const checkDatePkt = new Date(startDatePkt);
        checkDatePkt.setUTCDate(checkDatePkt.getUTCDate() + i);
        const dateKey = checkDatePkt.toISOString().split('T')[0];

        if (!dailyAdherence[dateKey]) {
          dailyAdherence[dateKey] = { taken: 0, total: 0 };
        }

        // isScheduledOnDate expects a date to check against
        if (this.isScheduledOnDate(schedule, new Date(checkDatePkt.getTime() - (5 * 60 * 60 * 1000)))) {
          for (const timeStr of times) {
            const dueAt = getUTCFromPKT(new Date(checkDatePkt.getTime() - (5 * 60 * 60 * 1000)), timeStr);

            // Skip doses in the future
            if (dueAt > now) continue;

            totalScheduledDoses++;
            dailyAdherence[dateKey].total++;

            const status = intakeMap.get(dueAt.toISOString());
            if (status === IntakeStatus.TAKEN) {
              totalTakenDoses++;
              dailyAdherence[dateKey].taken++;
            } else {
              if (status) {
                console.log(`DEBUG [ADHERENCE] Med: ${med.medicationName}, Date: ${dateKey}, Time: ${timeStr}, Status: ${status} (NOT TAKEN)`);
              } else {
                console.log(`DEBUG [ADHERENCE] Med: ${med.medicationName}, Date: ${dateKey}, Time: ${timeStr}, Status: MISSING (NOT TAKEN)`);
              }
            }
          }
        }
      }
    }

    const adherenceRate = totalScheduledDoses > 0 ? totalTakenDoses / totalScheduledDoses : 1.0;
    console.log(`DEBUG [ADHERENCE] Result: ${adherenceRate * 100}% (${totalTakenDoses}/${totalScheduledDoses})`);

    const history = Object.entries(dailyAdherence)
      .map(([date, stats]) => ({
        date,
        adherence: stats.total > 0 ? stats.taken / stats.total : 1.0,
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return {
      adherenceRate,
      history,
    };
  }

  /**
   * Get adherence streak (consecutive days taken all scheduled doses)
   */
  async getAdherenceStreak(context: ActorContext) {
    const now = new Date(); // Use absolute UTC time
    let streak = 0;
    let dayOffset = 0;

    const medications = await this.prisma.medication.findMany({
      where: { elderUserId: context.elderUserId },
      include: {
        schedules: {
          orderBy: { createdAt: 'desc' },
          take: 1
        }
      } as any,
    });

    if (medications.length === 0) return { streak: 0 };

    while (true) {
      const pktNow = new Date(now.getTime() + (5 * 60 * 60 * 1000));
      const checkDatePkt = new Date(pktNow);
      checkDatePkt.setUTCHours(0, 0, 0, 0);
      checkDatePkt.setUTCDate(checkDatePkt.getUTCDate() - dayOffset);
      
      const checkDateUtc = new Date(checkDatePkt.getTime() - (5 * 60 * 60 * 1000));

      // Don't go back too far (max 365 days for performance)
      if (dayOffset > 365) break;

      let allDosesTakenOnDay = true;
      let hadDosesOnDay = false;

      for (const med of medications) {
        if (!med.schedules?.[0]) continue;
        const schedule = med.schedules[0];
        
        if (this.isScheduledOnDate(schedule, checkDateUtc)) {
          let times = schedule.timesLocal || [];
          if (typeof times === 'string') {
            try {
              times = JSON.parse(times);
            } catch (e) {
              times = [];
            }
          }

          for (const timeStr of times) {
            const dueAt = getUTCFromPKT(checkDateUtc, timeStr);

            // Skip future doses for today's check
            if (dueAt > now) continue;

            hadDosesOnDay = true;
            const intake = await this.prisma.medIntake.findFirst({
              where: {
                medScheduleId: schedule.medScheduleId,
                dueAt,
              },
            } as any);

            if (!intake || intake.status !== IntakeStatus.TAKEN) {
              allDosesTakenOnDay = false;
              console.log(`DEBUG [STREAK] Broken at ${dueAt.toISOString()} for ${med.medicationName}. Status: ${intake?.status || 'MISSING'}`);
              break;
            }
          }
        }
        if (!allDosesTakenOnDay) break;
      }

      if (hadDosesOnDay && allDosesTakenOnDay) {
        streak++;
      } else if (hadDosesOnDay && !allDosesTakenOnDay) {
        break;
      }

      dayOffset++;
    }

    return { streak };
  }

  /**
   * Get medication status for a specific date
   */
  async getMedicationStatus(context: ActorContext, targetDate: Date) {
    // targetDate might be UTC midnight from frontend, ensure we handle it as PKT day
    const dateStart = new Date(targetDate);
    dateStart.setHours(0, 0, 0, 0);

    const dateEnd = new Date(targetDate);
    dateEnd.setHours(23, 59, 59, 999);

    const nowPKT = this.getNowPKT();

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
      const medStart = new Date(schedule.startDate);
      medStart.setHours(0,0,0,0);
      if (medStart > dateEnd) continue;
      
      if (schedule.endDate) {
        const medEnd = new Date(schedule.endDate);
        medEnd.setHours(23,59,59,999);
        if (medEnd < dateStart) continue;
      }

      if (!this.isScheduledOnDate(schedule, dateStart)) continue;

      const medicationStatus: any = {
        medicineId: medication.medicationId.toString(),
        name: medication.medicationName,
        scheduledTimes: [],
        status: 'upcoming',
      };

      for (let timeVal of times) {
        const timeStr = typeof timeVal === 'object' && timeVal !== null && 'time' in timeVal ? (timeVal as any).time : timeVal;
        if (typeof timeStr !== 'string') continue;
        
        // Use proper UTC point-in-time conversion
        const scheduledTime = getUTCFromPKT(dateStart, timeStr);

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
        } else if (scheduledTime < nowPKT) {
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
      adherence: takenCount + missedCount > 0 ? takenCount / (takenCount + missedCount) : 1.0,
      takenCount,
      missedCount,
      upcomingCount,
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
    const now = getPKTDate();
    const baseDate = getPKTDateOnly();

    for (const medication of medications) {
      if ((medication as any).schedules.length === 0) continue;

      const schedule = (medication as any).schedules[0];
      const times = (schedule as any).timesLocal as string[];

      if (!Array.isArray(times)) continue;

      // Map medication once per medication, not once per reminder time
      const mappedMedicine = await this.mapToResponse(context, medication);

      for (let timeVal of times) {
        const timeStr = typeof timeVal === 'object' && timeVal !== null && 'time' in timeVal ? (timeVal as any).time : timeVal;
        if (typeof timeStr !== 'string') continue;
        
        // Use proper utility to get correct UTC point-in-time for today's dose
        const todayReminder = getUTCFromPKT(baseDate, timeStr);

        // Check if today's dose is already logged
        // Use a 1-minute window around todayReminder to be precision-resilient
        const startTime = new Date(todayReminder.getTime() - 30000);
        const endTime = new Date(todayReminder.getTime() + 30000);

        const intake = await this.prisma.medIntake.findFirst({
          where: {
            schedule: {
              medicationId: medication.medicationId,
            },
            dueAt: {
              gte: startTime,
              lte: endTime,
            },
          },
        } as any);

        const isMissedHighPriority = intake && intake.status === IntakeStatus.MISSED && medication.priority === 'high';
        const hasIntakeRecord = !!intake;

        let finalReminderTime = new Date(todayReminder);
        if (hasIntakeRecord && todayReminder < now && !isMissedHighPriority) {
          // If already logged and in the past, shift to tomorrow
          // EXCEPT if it's a high-priority missed dose (stay on today so user can correct it)
          finalReminderTime.setUTCDate(todayReminder.getUTCDate() + 1);
        } else if (!hasIntakeRecord) {
          // If NOT logged, keep it as today's dose (even if overdue)
          finalReminderTime = todayReminder;
        } else if (hasIntakeRecord && todayReminder >= now) {
          // Already logged but in the future? (e.g. user logged ahead of time)
          // Shift to tomorrow to show next dose
          finalReminderTime.setUTCDate(todayReminder.getUTCDate() + 1);
        }

        reminders.push({
          medicine: mappedMedicine,
          time: timeStr,
          reminderTime: finalReminderTime.toISOString(),
          // Correct: Status is only inherited if the reminder is for the SAME time as the intake
          // If we shifted to tomorrow, the status for tomorrow's dose is 'pending'
          status: (intake && finalReminderTime.getTime() === todayReminder.getTime()) 
            ? intake.status.toLowerCase() 
            : 'pending',
        });
      }
    }

    return reminders.sort((a, b) => a.reminderTime.localeCompare(b.reminderTime));
  }
}
