import { Module } from '@nestjs/common';
import { CaregiverNotesService } from './caregiver-notes.service';
import { CaregiverNotesController } from './caregiver-notes.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AccessControlService } from '../common/services/access-control.service';

@Module({
  imports: [PrismaModule],
  controllers: [CaregiverNotesController],
  providers: [CaregiverNotesService, AccessControlService],
  exports: [CaregiverNotesService],
})
export class CaregiverNotesModule {}

