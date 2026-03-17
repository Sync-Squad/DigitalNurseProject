import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDocumentDto, DocumentType, DocumentVisibility } from './dto/create-document.dto';
import { ActorContext } from '../common/services/access-control.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class DocumentsService {
  private readonly uploadDir: string;

  constructor(private prisma: PrismaService) {
    // Load base path from env, fallback to default if not set
    this.uploadDir = process.env.DOCUMENTS_BASE_PATH || path.join(process.cwd(), 'uploads', 'documents');
    
    // Ensure base upload directory exists
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Smart Path Resolver: Returns absolute path regardless of storage format
   */
  private getAbsolutePath(storedPath: string): string {
    if (!storedPath) return '';
    
    // Check if it's already an absolute path (starts with drive letter like C:\ or C:/, or / or \)
    if (/^[a-zA-Z]:[\\\/]/.test(storedPath) || storedPath.startsWith('/') || storedPath.startsWith('\\')) {
      return storedPath;
    }
    
    // Otherwise, it's a relative path (e.g., "100/file.jpg")
    return path.join(this.uploadDir, storedPath);
  }

  /**
   * Save uploaded file
   */
  private async saveFile(file: any, userId: bigint, title: string): Promise<string> {
    const timestamp = Date.now();
    let extension = path.extname(file.originalname);
    
    // If extension is missing (common on some web uploads), derive from mimetype
    if (!extension && file.mimetype) {
      const mimeMap: { [key: string]: string } = {
        'application/pdf': '.pdf',
        'image/jpeg': '.jpg',
        'image/jpg': '.jpg',
        'image/png': '.png',
        'image/gif': '.gif',
        'text/plain': '.txt',
        'application/msword': '.doc',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
      };
      extension = mimeMap[file.mimetype] || '';
    }

    const cleanTitle = title.replace(/[^\w\s-]/g, '').replace(/\s+/g, '_');
    const fileName = `${cleanTitle}_${timestamp}${extension}`;
    
    // Create user-specific folder
    const userDir = path.join(this.uploadDir, userId.toString());
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }

    const fullPath = path.join(userDir, fileName);
    const relativePath = path.join(userId.toString(), fileName);

    fs.writeFileSync(fullPath, file.buffer);

    return relativePath;
  }

  /**
   * Create document
   */
  async create(context: ActorContext, createDto: CreateDocumentDto, file: any) {
    const filePath = await this.saveFile(file, context.elderUserId, createDto.title);
    
    // Robust fileType detection
    let fileType = file.mimetype;
    if (!fileType || fileType === 'application/octet-stream') {
      const ext = path.extname(filePath).toLowerCase();
      if (ext === '.pdf') fileType = 'application/pdf';
      else if (ext === '.jpg' || ext === '.jpeg') fileType = 'image/jpeg';
      else if (ext === '.png') fileType = 'image/png';
      else if (ext === '.gif') fileType = 'image/gif';
      else if (ext === '.txt') fileType = 'text/plain';
      else if (ext === '.doc' || ext === '.docx') fileType = 'application/msword';
    }

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

    const fullPath = this.getAbsolutePath(document.filePath);
    if (!fs.existsSync(fullPath)) {
      throw new NotFoundException('File not found');
    }

    // Robust MIME type detection for serving
    let mimeType = document.fileType;
    if (!mimeType || mimeType === 'application/octet-stream') {
      mimeType = this.getMimeType(path.extname(fullPath));
    }

    return {
      filePath: fullPath,
      fileName: path.basename(fullPath),
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
    const fullPath = this.getAbsolutePath(document.filePath);
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
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
    const fileName = path.basename(document.filePath);
    
    // Robustly determine fileType if generic or missing
    let fileType = document.fileType;
    if (!fileType || fileType === 'application/octet-stream' || fileType.length > 50) {
      const ext = path.extname(document.filePath).toLowerCase();
      if (ext === '.pdf') fileType = 'application/pdf';
      else if (ext === '.jpg' || ext === '.jpeg') fileType = 'image/jpeg';
      else if (ext === '.png') fileType = 'image/png';
      else if (ext === '.gif') fileType = 'image/gif';
      else if (ext === '.txt') fileType = 'text/plain';
      else if (ext === '.doc' || ext === '.docx') fileType = 'application/msword';
    }
    
    return {
      id: documentId,
      title: document.title,
      type: document.documentType,
      fileName,
      fileUrl: `documents/${documentId}/view`,
      abspath: this.getAbsolutePath(document.filePath),
      fileType,
      uploadDate: document.uploadedAt.toISOString(),
      visibility: document.visibility,
      description: document.description || null,
      userId: document.userId.toString(),
    };
  }
}

