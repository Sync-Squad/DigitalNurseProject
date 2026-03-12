import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDocumentDto, DocumentType, DocumentVisibility } from './dto/create-document.dto';
import { ActorContext } from '../common/services/access-control.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class DocumentsService {
  private readonly uploadDir = path.join(process.cwd(), 'uploads', 'documents');

  constructor(private prisma: PrismaService) {
    // Ensure upload directory exists
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Save uploaded file
   */
  private async saveFile(file: any, userId: bigint): Promise<string> {
    const fileName = `${userId}_${Date.now()}_${file.originalname}`;
    const filePath = path.join(this.uploadDir, fileName);

    fs.writeFileSync(filePath, file.buffer);

    return filePath;
  }

  /**
   * Create document
   */
  async create(context: ActorContext, createDto: CreateDocumentDto, file: any) {
    const filePath = await this.saveFile(file, context.elderUserId);
    const fileType = file.mimetype || path.extname(file.originalname).substring(1);

    const document = await this.prisma.userDocument.create({
      data: {
        userId: context.elderUserId,
        documentType: createDto.type,
        title: createDto.title,
        description: createDto.description || null,
        filePath,
        fileType,
        uploadedBy: context.actorUserId,
        visibility: createDto.visibility || DocumentVisibility.PRIVATE,
        uploadedAt: createDto.uploadDate ? new Date(createDto.uploadDate) : new Date(),
      },
    });

    return this.mapToResponse(document);
  }

  /**
   * Find all documents for a user
   */
  async findAll(context: ActorContext, type?: DocumentType) {
    const where: any = { userId: context.elderUserId };
    if (type) {
      where.documentType = type;
    }

    const documents = await this.prisma.userDocument.findMany({
      where,
      orderBy: {
        uploadedAt: 'desc',
      },
    });

    return documents.map((doc) => this.mapToResponse(doc));
  }

  /**
   * Find one document by ID
   */
  async findOne(context: ActorContext, documentId: bigint) {
    const document = await this.prisma.userDocument.findFirst({
      where: {
        documentId,
        userId: context.elderUserId,
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    return this.mapToResponse(document);
  }

  /**
   * Get document file
   */
  async getFile(context: ActorContext, documentId: bigint) {
    const document = await this.prisma.userDocument.findFirst({
      where: {
        documentId,
        userId: context.elderUserId,
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    if (!fs.existsSync(document.filePath)) {
      throw new NotFoundException('File not found');
    }

    // Get MIME type based on file extension
    const mimeType = this.getMimeType(document.fileType || path.extname(document.filePath));

    return {
      filePath: document.filePath,
      fileName: path.basename(document.filePath),
      fileType: document.fileType,
      mimeType,
    };
  }

  /**
   * Get MIME type from file extension or file type
   */
  private getMimeType(fileType: string): string {
    const ext = fileType.toLowerCase();
    
    // Handle full MIME types
    if (ext.includes('/')) {
      return ext;
    }

    // Map extensions to MIME types
    const mimeTypes: { [key: string]: string } = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
    };

    // Remove leading dot if present
    const cleanExt = ext.replace(/^\./, '');
    return mimeTypes[cleanExt] || 'application/octet-stream';
  }

  /**
   * Update document metadata
   */
  async update(
    context: ActorContext,
    documentId: bigint,
    updateDto: Partial<CreateDocumentDto>,
  ) {
    const document = await this.prisma.userDocument.findFirst({
      where: {
        documentId,
        userId: context.elderUserId,
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    const updateData: any = {};
    if (updateDto.title) updateData.title = updateDto.title;
    if (updateDto.description !== undefined) updateData.description = updateDto.description;
    if (updateDto.type) updateData.documentType = updateDto.type;
    if (updateDto.visibility !== undefined) updateData.visibility = updateDto.visibility;

    const updated = await this.prisma.userDocument.update({
      where: { documentId },
      data: updateData,
    });

    return this.mapToResponse(updated);
  }

  /**
   * Update document visibility
   */
  async updateVisibility(
    context: ActorContext,
    documentId: bigint,
    visibility: DocumentVisibility,
  ) {
    const document = await this.prisma.userDocument.findFirst({
      where: {
        documentId,
        userId: context.elderUserId,
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    const updated = await this.prisma.userDocument.update({
      where: { documentId },
      data: { visibility },
    });

    return this.mapToResponse(updated);
  }

  /**
   * Delete document
   */
  async remove(context: ActorContext, documentId: bigint) {
    const document = await this.prisma.userDocument.findFirst({
      where: {
        documentId,
        userId: context.elderUserId,
      },
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    // Delete file if exists
    if (fs.existsSync(document.filePath)) {
      fs.unlinkSync(document.filePath);
    }

    await this.prisma.userDocument.delete({
      where: { documentId },
    });

    return { message: 'Document deleted successfully' };
  }

  /**
   * Map database model to API response
   */
  private mapToResponse(document: any) {
    const documentId = document.documentId.toString();
    return {
      id: documentId,
      title: document.title,
      type: document.documentType,
      filePath: document.filePath, // Keep for backward compatibility
      fileUrl: `/documents/${documentId}/file`, // Add accessible URL
      fileType: document.fileType,
      uploadDate: document.uploadedAt.toISOString(),
      visibility: document.visibility,
      description: document.description || null,
      userId: document.userId.toString(),
    };
  }
}

