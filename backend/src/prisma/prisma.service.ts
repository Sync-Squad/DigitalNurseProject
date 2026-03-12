import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    try {
      await this.$connect();
      await this.$executeRawUnsafe("SET TIME ZONE 'Asia/Karachi';");
    } catch (error) {
      console.warn(
        '⚠️  Database connection failed. Some features may not work without proper database setup.',
      );
      console.warn(
        '   To fix this, set up PostgreSQL and configure DATABASE_URL in .env file',
      );
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
