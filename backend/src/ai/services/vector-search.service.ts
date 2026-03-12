import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmbeddingService } from './embedding.service';
import { AppConfigService } from '../../config/config.service';
import { SemanticSearchDto } from '../dto/semantic-search.dto';

export interface SearchResult {
  id: string;
  entityType: string;
  content: string;
  similarity: number;
  metadata: Record<string, any>;
}

@Injectable()
export class VectorSearchService {
  private readonly logger = new Logger(VectorSearchService.name);
  private defaultThreshold: number = 0.7;

  constructor(
    private prisma: PrismaService,
    private embeddingService: EmbeddingService,
    private appConfigService: AppConfigService,
  ) {
    this.initializeConfig();
  }

  private async initializeConfig() {
    try {
      const thresholdConfig = await this.appConfigService.getConfigByKey(
        'ai_semantic_search_threshold',
      );
      if (thresholdConfig) {
        this.defaultThreshold = parseFloat(thresholdConfig.configValue);
      }
    } catch (error) {
      this.logger.error('Error initializing search config:', error);
    }
  }

  /**
   * Search across all tables with vector embeddings
   */
  async searchAll(dto: SemanticSearchDto): Promise<SearchResult[]> {
    const queryEmbedding = await this.embeddingService.generateEmbedding(
      dto.query,
    );
    const threshold = dto.threshold ?? this.defaultThreshold;
    const limit = dto.limit ?? 10;

    const results: SearchResult[] = [];

    // Search caregiver notes
    if (!dto.entityType || dto.entityType === 'caregiver_notes') {
      const notes = await this.searchCaregiverNotes(
        queryEmbedding,
        dto.elderUserId,
        threshold,
        limit,
      );
      results.push(...notes);
    }

    // Search medications
    if (!dto.entityType || dto.entityType === 'medications') {
      const medications = await this.searchMedications(
        queryEmbedding,
        dto.elderUserId,
        threshold,
        limit,
      );
      results.push(...medications);
    }

    // Search vital measurements
    if (!dto.entityType || dto.entityType === 'vital_measurements') {
      const vitals = await this.searchVitalMeasurements(
        queryEmbedding,
        dto.elderUserId,
        threshold,
        limit,
      );
      results.push(...vitals);
    }

    // Search diet logs
    if (!dto.entityType || dto.entityType === 'diet_logs') {
      const dietLogs = await this.searchDietLogs(
        queryEmbedding,
        dto.userId,
        threshold,
        limit,
      );
      results.push(...dietLogs);
    }

    // Search exercise logs
    if (!dto.entityType || dto.entityType === 'exercise_logs') {
      const exerciseLogs = await this.searchExerciseLogs(
        queryEmbedding,
        dto.userId,
        threshold,
        limit,
      );
      results.push(...exerciseLogs);
    }

    // Sort by similarity and limit
    results.sort((a, b) => b.similarity - a.similarity);
    return results.slice(0, limit);
  }

  /**
   * Search caregiver notes
   */
  async searchCaregiverNotes(
    queryEmbedding: number[],
    elderUserId?: bigint,
    threshold: number = 0.7,
    limit: number = 10,
  ): Promise<SearchResult[]> {
    const embeddingArray = `'[${queryEmbedding.join(',')}]'::vector`;
    let query = `
      SELECT 
        note_id::text as id,
        'caregiver_notes' as entity_type,
        note_text as content,
        1 - (embedding <=> ${embeddingArray}) as similarity,
        jsonb_build_object(
          'elderUserId', elder_user_id::text,
          'caregiverUserId', caregiver_user_id::text,
          'createdAt', created_at
        ) as metadata
      FROM caregiver_notes
      WHERE embedding IS NOT NULL
        AND (1 - (embedding <=> ${embeddingArray})) >= ${threshold}
    `;

    if (elderUserId) {
      query += ` AND elder_user_id = ${elderUserId}`;
    }

    query += ` ORDER BY embedding <=> ${embeddingArray} LIMIT ${limit}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => ({
      id: r.id,
      entityType: r.entity_type,
      content: r.content,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata,
    }));
  }

  /**
   * Search medications
   */
  async searchMedications(
    queryEmbedding: number[],
    elderUserId?: bigint,
    threshold: number = 0.7,
    limit: number = 10,
  ): Promise<SearchResult[]> {
    const embeddingArray = `'[${queryEmbedding.join(',')}]'::vector`;
    let query = `
      SELECT 
        "medicationId"::text as id,
        'medications' as entity_type,
        COALESCE(notes, instructions, '') as content,
        1 - (notes_embedding <=> ${embeddingArray}) as similarity,
        jsonb_build_object(
          'medicationName', "medicationName",
          'elderUserId', "elderUserId"::text,
          'createdAt', "createdAt"
        ) as metadata
      FROM medications
      WHERE notes_embedding IS NOT NULL
        AND (1 - (notes_embedding <=> ${embeddingArray})) >= ${threshold}
    `;

    if (elderUserId) {
      query += ` AND "elderUserId" = ${elderUserId}`;
    }

    query += ` ORDER BY notes_embedding <=> ${embeddingArray} LIMIT ${limit}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => ({
      id: r.id,
      entityType: r.entity_type,
      content: r.content,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata,
    }));
  }

  /**
   * Search vital measurements
   */
  async searchVitalMeasurements(
    queryEmbedding: number[],
    elderUserId?: bigint,
    threshold: number = 0.7,
    limit: number = 10,
  ): Promise<SearchResult[]> {
    const embeddingArray = `'[${queryEmbedding.join(',')}]'::vector`;
    let query = `
      SELECT 
        "vitalMeasurementId"::text as id,
        'vital_measurements' as entity_type,
        COALESCE(notes, '') as content,
        1 - (notes_embedding <=> ${embeddingArray}) as similarity,
        jsonb_build_object(
          'kindCode', "kindCode",
          'elderUserId', "elderUserId"::text,
          'recordedAt', "recordedAt"
        ) as metadata
      FROM vital_measurements
      WHERE notes_embedding IS NOT NULL
        AND (1 - (notes_embedding <=> ${embeddingArray})) >= ${threshold}
    `;

    if (elderUserId) {
      query += ` AND "elderUserId" = ${elderUserId}`;
    }

    query += ` ORDER BY notes_embedding <=> ${embeddingArray} LIMIT ${limit}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => ({
      id: r.id,
      entityType: r.entity_type,
      content: r.content,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata,
    }));
  }

  /**
   * Search diet logs
   */
  async searchDietLogs(
    queryEmbedding: number[],
    userId?: bigint,
    threshold: number = 0.7,
    limit: number = 10,
  ): Promise<SearchResult[]> {
    const embeddingArray = `'[${queryEmbedding.join(',')}]'::vector`;
    let query = `
      SELECT 
        diet_id::text as id,
        'diet_logs' as entity_type,
        COALESCE(food_items, notes, '') as content,
        GREATEST(
          COALESCE(1 - (food_items_embedding <=> ${embeddingArray}), 0),
          COALESCE(1 - (notes_embedding <=> ${embeddingArray}), 0)
        ) as similarity,
        jsonb_build_object(
          'mealType', meal_type,
          'userId', user_id::text,
          'logDate', log_date
        ) as metadata
      FROM diet_logs
      WHERE (food_items_embedding IS NOT NULL OR notes_embedding IS NOT NULL)
        AND GREATEST(
          COALESCE(1 - (food_items_embedding <=> ${embeddingArray}), 0),
          COALESCE(1 - (notes_embedding <=> ${embeddingArray}), 0)
        ) >= ${threshold}
    `;

    if (userId) {
      query += ` AND user_id = ${userId}`;
    }

    query += ` ORDER BY similarity DESC LIMIT ${limit}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => ({
      id: r.id,
      entityType: r.entity_type,
      content: r.content,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata,
    }));
  }

  /**
   * Search exercise logs
   */
  async searchExerciseLogs(
    queryEmbedding: number[],
    userId?: bigint,
    threshold: number = 0.7,
    limit: number = 10,
  ): Promise<SearchResult[]> {
    const embeddingArray = `'[${queryEmbedding.join(',')}]'::vector`;
    let query = `
      SELECT 
        exercise_id::text as id,
        'exercise_logs' as entity_type,
        COALESCE(description, notes, '') as content,
        GREATEST(
          COALESCE(1 - (description_embedding <=> ${embeddingArray}), 0),
          COALESCE(1 - (notes_embedding <=> ${embeddingArray}), 0)
        ) as similarity,
        jsonb_build_object(
          'exerciseType', exercise_type,
          'userId', user_id::text,
          'logDate', log_date
        ) as metadata
      FROM exercise_logs
      WHERE (description_embedding IS NOT NULL OR notes_embedding IS NOT NULL)
        AND GREATEST(
          COALESCE(1 - (description_embedding <=> ${embeddingArray}), 0),
          COALESCE(1 - (notes_embedding <=> ${embeddingArray}), 0)
        ) >= ${threshold}
    `;

    if (userId) {
      query += ` AND user_id = ${userId}`;
    }

    query += ` ORDER BY similarity DESC LIMIT ${limit}`;

    const results = await this.prisma.$queryRawUnsafe(query);
    return (results as any[]).map((r) => ({
      id: r.id,
      entityType: r.entity_type,
      content: r.content,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata,
    }));
  }
}

