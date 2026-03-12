import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AIAssistantService } from './services/ai-assistant.service';
import { AIInsightsService } from './services/ai-insights.service';
import { AIHealthAnalystService } from './services/ai-health-analyst.service';
import { VectorSearchService } from './services/vector-search.service';
import { DocumentProcessorService } from './services/document-processor.service';
import { BatchEmbeddingService } from './services/batch-embedding.service';
import { AutomatedInsightsService } from './services/automated-insights.service';
import { ChatMessageDto, CreateConversationDto } from './dto/chat-message.dto';
import { GenerateInsightDto, GetInsightsDto } from './dto/generate-insight.dto';
import { HealthAnalysisDto } from './dto/health-analysis.dto';
import { SemanticSearchDto } from './dto/semantic-search.dto';

@ApiTags('AI')
@Controller('ai')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AIController {
  constructor(
    private aiAssistantService: AIAssistantService,
    private aiInsightsService: AIInsightsService,
    private healthAnalystService: AIHealthAnalystService,
    private vectorSearchService: VectorSearchService,
    private documentProcessorService: DocumentProcessorService,
    private batchEmbeddingService: BatchEmbeddingService,
    private automatedInsightsService: AutomatedInsightsService,
  ) {}

  @Post('chat')
  @ApiOperation({ summary: 'Chat with AI assistant' })
  @ApiResponse({ status: 200, description: 'AI response' })
  async chat(
    @CurrentUser() user: any,
    @Body() dto: ChatMessageDto,
  ) {
    return this.aiAssistantService.chat(BigInt(user.userId), dto);
  }

  @Get('conversations')
  @ApiOperation({ summary: 'Get all conversations' })
  @ApiResponse({ status: 200, description: 'List of conversations' })
  async getConversations(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    return this.aiAssistantService.getConversations(
      BigInt(user.userId),
      elderUserId ? BigInt(elderUserId) : undefined,
    );
  }

  @Get('conversations/:conversationId')
  @ApiOperation({ summary: 'Get conversation history' })
  @ApiResponse({ status: 200, description: 'Conversation with messages' })
  async getConversation(
    @CurrentUser() user: any,
    @Param('conversationId', ParseIntPipe) conversationId: number,
  ) {
    return this.aiAssistantService.getConversation(
      BigInt(conversationId),
      BigInt(user.userId),
    );
  }

  @Get('insights')
  @ApiOperation({ summary: 'Get AI insights' })
  @ApiResponse({ status: 200, description: 'List of insights' })
  async getInsights(
    @CurrentUser() user: any,
    @Query() dto: GetInsightsDto,
  ) {
    return this.aiInsightsService.getInsights(BigInt(user.userId), dto);
  }

  @Post('insights/generate')
  @ApiOperation({ summary: 'Generate a new AI insight' })
  @ApiResponse({ status: 201, description: 'Insight generated' })
  async generateInsight(
    @CurrentUser() user: any,
    @Body() dto: GenerateInsightDto,
  ) {
    return this.aiInsightsService.generateInsight(dto, BigInt(user.userId));
  }

  @Put('insights/:insightId/read')
  @ApiOperation({ summary: 'Mark insight as read' })
  @ApiResponse({ status: 200, description: 'Insight marked as read' })
  async markInsightAsRead(
    @CurrentUser() user: any,
    @Param('insightId', ParseIntPipe) insightId: number,
  ) {
    await this.aiInsightsService.markAsRead(
      BigInt(insightId),
      BigInt(user.userId),
    );
    return { message: 'Insight marked as read' };
  }

  @Put('insights/:insightId/archive')
  @ApiOperation({ summary: 'Archive insight' })
  @ApiResponse({ status: 200, description: 'Insight archived' })
  async archiveInsight(
    @CurrentUser() user: any,
    @Param('insightId', ParseIntPipe) insightId: number,
  ) {
    await this.aiInsightsService.archiveInsight(
      BigInt(insightId),
      BigInt(user.userId),
    );
    return { message: 'Insight archived' };
  }

  @Post('analyze')
  @ApiOperation({ summary: 'Analyze health data' })
  @ApiResponse({ status: 200, description: 'Health analysis results' })
  async analyzeHealth(
    @CurrentUser() user: any,
    @Body() dto: HealthAnalysisDto,
  ) {
    const elderUserId = dto.elderUserId
      ? BigInt(dto.elderUserId)
      : BigInt(user.userId);
    const startDate = dto.startDate ? new Date(dto.startDate) : undefined;
    const endDate = dto.endDate ? new Date(dto.endDate) : undefined;

    return this.healthAnalystService.analyzeHealth(
      elderUserId,
      startDate,
      endDate,
    );
  }

  @Post('search')
  @ApiOperation({ summary: 'Semantic search across health data' })
  @ApiResponse({ status: 200, description: 'Search results' })
  async search(
    @CurrentUser() user: any,
    @Body() dto: SemanticSearchDto,
  ) {
    dto.userId = BigInt(user.userId);
    if (dto.elderUserId) {
      dto.elderUserId = BigInt(dto.elderUserId);
    }
    return this.vectorSearchService.searchAll(dto);
  }

  @Post('documents/:documentId/process')
  @ApiOperation({ summary: 'Process document for Q&A' })
  @ApiResponse({ status: 200, description: 'Document processed' })
  async processDocument(
    @CurrentUser() user: any,
    @Param('documentId', ParseIntPipe) documentId: number,
    @Body('text') text: string,
  ) {
    await this.documentProcessorService.processDocument(
      BigInt(documentId),
      BigInt(user.userId),
      text,
    );
    return { message: 'Document processed successfully' };
  }

  @Post('documents/:documentId/ask')
  @ApiOperation({ summary: 'Ask question about a document' })
  @ApiResponse({ status: 200, description: 'Answer with sources' })
  async askDocument(
    @Param('documentId', ParseIntPipe) documentId: number,
    @Body('question') question: string,
  ) {
    return this.documentProcessorService.answerQuestion(
      BigInt(documentId),
      question,
    );
  }

  @Post('batch-embedding/process')
  @ApiOperation({ summary: 'Process batch embeddings for existing data' })
  @ApiResponse({ status: 200, description: 'Batch processing results' })
  async processBatchEmbeddings() {
    return this.batchEmbeddingService.processAll();
  }

  @Post('insights/generate-for-user')
  @ApiOperation({ summary: 'Manually generate insights for a user' })
  @ApiResponse({ status: 200, description: 'Insights generated' })
  async generateInsightsForUser(
    @CurrentUser() user: any,
    @Body('elderUserId', ParseIntPipe) elderUserId: number,
  ) {
    return this.automatedInsightsService.generateInsightsForUser(
      BigInt(user.userId),
      BigInt(elderUserId),
    );
  }
}

