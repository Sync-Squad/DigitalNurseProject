import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/dto/create-notification.dto';
import { getPKTDate } from '../common/utils/date-utils';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MedicinePriority } from './dto/create-medication.dto';

@Injectable()
export class MedicationNotificationService {
  private readonly logger = new Logger(MedicationNotificationService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async handleCron() {
    const now = getPKTDate();
    const currentTime = now.toTimeString().substring(0, 5); // "HH:mm"
    const currentDay = now.getDay(); // 0=Sunday, 1=Monday...
    
    // In our DB/logic: 1=Monday, 7=Sunday
    const dbDay = currentDay === 0 ? 7 : currentDay;
    const dayBitValue = 1 << (dbDay - 1);

    this.logger.debug(`Checking for medications due at ${currentTime} (Day Bit: ${dayBitValue})`);

    // Find all active schedules that include the current day
    const schedules = await this.prisma.medSchedule.findMany({
      where: {
        startDate: { lte: now },
        OR: [
          { endDate: null },
          { endDate: { gte: now } },
        ],
        AND: [
            // Bitwise check for day of week
            // Note: Prisma doesn't directly support bitwise operators in 'where' easily across providers
            // We might need to filter in JS or use a raw query if performance is an issue.
            // For now, let's fetch all active schedules and filter.
        ]
      },
      include: {
        medication: {
          include: {
            user: true,
          }
        }
      }
    });

    const activeSchedules = schedules.filter(s => (s.daysMask & dayBitValue) !== 0);

    for (const schedule of activeSchedules) {
      const times = schedule.timesLocal as string[];
      if (!Array.isArray(times)) continue;

      if (times.includes(currentTime)) {
        this.logger.log(`Medication due: ${schedule.medication.medicationName} for user ${schedule.medication.elderUserId}`);

        // 1. Create/Check MedIntake
        const dueAt = new Date(now);
        dueAt.setSeconds(0, 0);

        const existingIntake = await this.prisma.medIntake.findFirst({
          where: {
            medScheduleId: schedule.medScheduleId,
            dueAt: dueAt,
          }
        });

        if (!existingIntake) {
          await this.prisma.medIntake.create({
            data: {
              medScheduleId: schedule.medScheduleId,
              dueAt: dueAt,
              status: 'due',
              createdAt: getPKTDate(),
              updatedAt: getPKTDate(),
            }
          });
        }

        // 2. Create Notification
        // Check if notification already exists to avoid duplication if cron runs slightly off
        const existingNotif = await this.prisma.notification.findFirst({
          where: {
            userId: schedule.medication.elderUserId,
            title: 'Medicine Reminder',
            scheduledTime: dueAt,
          }
        });

        if (!existingNotif) {
          await this.notificationsService.create(
            { elderUserId: schedule.medication.elderUserId } as any,
            {
              title: 'Medicine Reminder',
              body: `It's time to take your ${schedule.medication.medicationName}.`,
              type: NotificationType.MEDICINE_REMINDER,
              scheduledTime: dueAt.toISOString(),
              actionData: {
                medicationId: schedule.medicationId.toString(),
                medScheduleId: schedule.medScheduleId.toString(),
                priority: (schedule.medication as any).priority,
              }
            }
          );
          this.logger.log(`Notification sent for ${schedule.medication.medicationName}`);
        }
      }
    }
  }
}
