import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { MedicationsModule } from './medications/medications.module';
import { VitalsModule } from './vitals/vitals.module';
import { CaregiversModule } from './caregivers/caregivers.module';
import { CaregiverNotesModule } from './caregiver-notes/caregiver-notes.module';
import { LifestyleModule } from './lifestyle/lifestyle.module';
import { DocumentsModule } from './documents/documents.module';
import { NotificationsModule } from './notifications/notifications.module';
import { LookupsModule } from './lookups/lookups.module';
import { DevicesModule } from './devices/devices.module';
import { AppConfigModule } from './config/config.module';
import { AIModule } from './ai/ai.module';
import { EmailModule } from './email/email.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { DashboardModule } from './dashboard/dashboard.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    SubscriptionsModule,
    MedicationsModule,
    VitalsModule,
    CaregiversModule,
    CaregiverNotesModule,
    LifestyleModule,
    DocumentsModule,
    NotificationsModule,
    LookupsModule,
    DevicesModule,
    AppConfigModule,
    AIModule,
    EmailModule,
    DashboardModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
