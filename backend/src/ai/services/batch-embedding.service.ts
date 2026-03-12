import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmbeddingService } from './embedding.service';

@Injectable()
export class BatchEmbeddingService {
  private readonly logger = new Logger(BatchEmbeddingService.name);
  private readonly BATCH_SIZE = 100;

  constructor(
    private prisma: PrismaService,
    private embeddingService: EmbeddingService,
  ) {}

  /**
   * Generate embeddings for all caregiver notes
   */
  async processCaregiverNotes(batchSize: number = this.BATCH_SIZE) {
    this.logger.log('Starting batch embedding for caregiver notes...');

    let offset = 0;
    let processed = 0;

    while (true) {
      // Use raw SQL since embedding is not in Prisma schema
      const notes = await this.prisma.$queryRawUnsafe<Array<{
        note_id: bigint;
        note_text: string;
      }>>(
        `SELECT note_id, note_text 
         FROM caregiver_notes 
         WHERE embedding IS NULL 
         LIMIT $1 OFFSET $2`,
        batchSize,
        offset,
      );

      if (notes.length === 0) break;

      for (const note of notes) {
        try {
          if (!note.note_text || note.note_text.trim().length === 0) continue;

          const embedding = await this.embeddingService.generateEmbedding(
            note.note_text,
          );
          const embeddingArray = `[${embedding.join(',')}]`;

          await this.prisma.$executeRawUnsafe(
            `UPDATE caregiver_notes 
             SET embedding = $1::vector 
             WHERE note_id = $2`,
            embeddingArray,
            note.note_id.toString(),
          );

          processed++;
          this.logger.log(`Processed caregiver note ${note.note_id}`);
        } catch (error) {
          this.logger.error(
            `Error processing caregiver note ${note.note_id}:`,
            error,
          );
        }
      }

      offset += batchSize;
    }

    this.logger.log(`Completed batch embedding for caregiver notes: ${processed} processed`);
    return processed;
  }

  /**
   * Generate embeddings for all medications
   */
  async processMedications(batchSize: number = this.BATCH_SIZE) {
    this.logger.log('Starting batch embedding for medications...');

    let offset = 0;
    let processed = 0;

    while (true) {
      // Use raw SQL since notes_embedding is not in Prisma schema
      const medications = await this.prisma.$queryRawUnsafe<Array<{
        medicationId: bigint;
        notes: string | null;
        instructions: string | null;
      }>>(
        `SELECT "medicationId", notes, instructions 
         FROM medications 
         WHERE notes_embedding IS NULL 
         LIMIT $1 OFFSET $2`,
        batchSize,
        offset,
      );

      if (medications.length === 0) break;

      for (const med of medications) {
        try {
          const text = [med.notes, med.instructions]
            .filter((t) => t && t.trim().length > 0)
            .join(' ');

          if (!text || text.trim().length === 0) continue;

          const embedding = await this.embeddingService.generateEmbedding(text);
          const embeddingArray = `[${embedding.join(',')}]`;

          await this.prisma.$executeRawUnsafe(
            `UPDATE medications 
             SET notes_embedding = $1::vector 
             WHERE "medicationId" = $2`,
            embeddingArray,
            med.medicationId.toString(),
          );

          processed++;
          this.logger.log(`Processed medication ${med.medicationId}`);
        } catch (error) {
          this.logger.error(
            `Error processing medication ${med.medicationId}:`,
            error,
          );
        }
      }

      offset += batchSize;
    }

    this.logger.log(`Completed batch embedding for medications: ${processed} processed`);
    return processed;
  }

  /**
   * Process all tables with text content
   */
  async processAll(batchSize: number = this.BATCH_SIZE) {
    this.logger.log('Starting batch embedding for all tables...');

    const results = {
      caregiverNotes: 0,
      medications: 0,
      vitalMeasurements: 0,
      dietLogs: 0,
      exerciseLogs: 0,
      medIntakes: 0,
      userDocuments: 0,
    };

    try {
      results.caregiverNotes = await this.processCaregiverNotes(batchSize);
      results.medications = await this.processMedications(batchSize);
      // Add similar methods for other tables
      // results.vitalMeasurements = await this.processVitalMeasurements(batchSize);
      // results.dietLogs = await this.processDietLogs(batchSize);
      // results.exerciseLogs = await this.processExerciseLogs(batchSize);
      // results.medIntakes = await this.processMedIntakes(batchSize);
      // results.userDocuments = await this.processUserDocuments(batchSize);
    } catch (error) {
      this.logger.error('Error in batch embedding process:', error);
      throw error;
    }

    this.logger.log('Completed batch embedding for all tables:', results);
    return results;
  }
}

