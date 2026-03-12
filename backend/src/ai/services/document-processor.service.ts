import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmbeddingService } from './embedding.service';

@Injectable()
export class DocumentProcessorService {
  private readonly logger = new Logger(DocumentProcessorService.name);
  private readonly CHUNK_SIZE = 1000; // Characters per chunk
  private readonly CHUNK_OVERLAP = 200; // Overlap between chunks

  constructor(
    private prisma: PrismaService,
    private embeddingService: EmbeddingService,
  ) {}

  /**
   * Process a document: chunk it and generate embeddings
   */
  async processDocument(
    documentId: bigint,
    userId: bigint,
    text: string,
  ): Promise<void> {
    // Delete existing chunks for this document
    await this.prisma.$executeRawUnsafe(
      `DELETE FROM document_chunks WHERE document_id = ${documentId}`,
    );

    // Chunk the text
    const chunks = this.chunkText(text);

    // Generate embeddings for each chunk
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      const embedding = await this.embeddingService.generateEmbedding(
        chunk.text,
      );

      // Store chunk with embedding
      const embeddingArray = `[${embedding.join(',')}]`;
      await this.prisma.$executeRawUnsafe(
        `INSERT INTO document_chunks 
         (document_id, user_id, chunk_index, chunk_text, chunk_embedding, token_count, metadata, created_at)
         VALUES ($1, $2, $3, $4, $5::vector, $6, $7, NOW())`,
        documentId.toString(),
        userId.toString(),
        i,
        chunk.text,
        embeddingArray,
        this.estimateTokenCount(chunk.text),
        JSON.stringify({
          startChar: chunk.startChar,
          endChar: chunk.endChar,
        }),
      );
    }

    this.logger.log(
      `Processed document ${documentId}: ${chunks.length} chunks created`,
    );
  }

  /**
   * Chunk text intelligently
   */
  private chunkText(text: string): Array<{
    text: string;
    startChar: number;
    endChar: number;
  }> {
    const chunks: Array<{ text: string; startChar: number; endChar: number }> =
      [];
    let start = 0;

    while (start < text.length) {
      const end = Math.min(start + this.CHUNK_SIZE, text.length);

      // Try to break at sentence boundary
      let actualEnd = end;
      if (end < text.length) {
        const sentenceEnd = text.lastIndexOf('.', end);
        const paragraphEnd = text.lastIndexOf('\n\n', end);
        const bestBreak = Math.max(sentenceEnd, paragraphEnd);
        if (bestBreak > start + this.CHUNK_SIZE * 0.5) {
          actualEnd = bestBreak + 1;
        }
      }

      const chunkText = text.substring(start, actualEnd).trim();
      if (chunkText.length > 0) {
        chunks.push({
          text: chunkText,
          startChar: start,
          endChar: actualEnd,
        });
      }

      // Move start with overlap
      start = actualEnd - this.CHUNK_OVERLAP;
      if (start < 0) start = 0;
    }

    return chunks;
  }

  /**
   * Estimate token count (rough approximation: 1 token ≈ 4 characters)
   */
  private estimateTokenCount(text: string): number {
    return Math.ceil(text.length / 4);
  }

  /**
   * Search document chunks for relevant information
   */
  async searchDocumentChunks(
    documentId: bigint,
    query: string,
    limit: number = 5,
    threshold: number = 0.7,
  ): Promise<Array<{ chunkText: string; similarity: number; metadata: any }>> {
    const queryEmbedding = await this.embeddingService.generateEmbedding(query);
    const embeddingArray = `[${queryEmbedding.join(',')}]`;

    const results = await this.prisma.$queryRawUnsafe(
      `SELECT 
        chunk_text,
        1 - (chunk_embedding <=> ${embeddingArray}::vector) as similarity,
        metadata
      FROM document_chunks
      WHERE document_id = ${documentId}
        AND chunk_embedding IS NOT NULL
        AND (1 - (chunk_embedding <=> ${embeddingArray}::vector)) >= ${threshold}
      ORDER BY chunk_embedding <=> ${embeddingArray}::vector
      LIMIT ${limit}`,
    );

    return (results as any[]).map((r) => ({
      chunkText: r.chunk_text,
      similarity: parseFloat(r.similarity),
      metadata: r.metadata ? JSON.parse(r.metadata) : {},
    }));
  }

  /**
   * Answer question about a document using RAG
   */
  async answerQuestion(
    documentId: bigint,
    question: string,
  ): Promise<{ answer: string; sources: any[] }> {
    // Find relevant chunks
    const relevantChunks = await this.searchDocumentChunks(
      documentId,
      question,
      5,
      0.6,
    );

    if (relevantChunks.length === 0) {
      return {
        answer: 'I could not find relevant information in the document to answer this question.',
        sources: [],
      };
    }

    // Build context from chunks
    const context = relevantChunks
      .map((chunk, i) => `[Chunk ${i + 1}]\n${chunk.chunkText}`)
      .join('\n\n');

    // Use Gemini to generate answer (simplified - you'd use the AI Assistant service)
    // For now, return the most relevant chunk
    const bestChunk = relevantChunks[0];
    return {
      answer: `Based on the document: ${bestChunk.chunkText.substring(0, 500)}...`,
      sources: relevantChunks.map((chunk) => ({
        text: chunk.chunkText.substring(0, 200),
        similarity: chunk.similarity,
        metadata: chunk.metadata,
      })),
    };
  }

  /**
   * Delete all chunks for a document
   */
  async deleteDocumentChunks(documentId: bigint): Promise<void> {
    await this.prisma.$executeRawUnsafe(
      `DELETE FROM document_chunks WHERE document_id = ${documentId}`,
    );
  }
}

