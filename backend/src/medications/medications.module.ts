import { Module } from '@nestjs/common';
import { MedicationsService } from './medications.service';
import { MedicationsController } from './medications.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AccessControlService } from '../common/services/access-control.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { MedicationNotificationService } from './medication-notification.service';

@Module({
  imports: [PrismaModule, NotificationsModule],
  controllers: [MedicationsController],
  providers: [
    MedicationsService,
    MedicationNotificationService,
    AccessControlService,
  ],
  exports: [MedicationsService],
})
export class MedicationsModule {}

