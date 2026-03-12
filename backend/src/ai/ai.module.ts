import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { AIController } from './ai.controller';
import { EmbeddingService } from './services/embedding.service';
import { VectorSearchService } from './services/vector-search.service';
import { AIHealthAnalystService } from './services/ai-health-analyst.service';
import { AIInsightsService } from './services/ai-insights.service';
import { AIAssistantService } from './services/ai-assistant.service';
import { DocumentProcessorService } from './services/document-processor.service';
import { BatchEmbeddingService } from './services/batch-embedding.service';
import { AutomatedInsightsService } from './services/automated-insights.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AppConfigModule } from '../config/config.module';

@Module({
  imports: [PrismaModule, AppConfigModule, ScheduleModule.forRoot()],
  controllers: [AIController],
  providers: [
    EmbeddingService,
    VectorSearchService,
    AIHealthAnalystService,
    AIInsightsService,
    AIAssistantService,
    DocumentProcessorService,
    BatchEmbeddingService,
    AutomatedInsightsService,
  ],
  exports: [
    EmbeddingService,
    VectorSearchService,
    AIHealthAnalystService,
    AIInsightsService,
    AIAssistantService,
    DocumentProcessorService,
    BatchEmbeddingService,
    AutomatedInsightsService,
  ],
})
export class AIModule {}

