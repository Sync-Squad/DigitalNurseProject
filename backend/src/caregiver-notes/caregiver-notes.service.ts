// @ts-nocheck
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCaregiverNoteDto } from './dto/create-caregiver-note.dto';
import { ActorContext } from '../common/services/access-control.service';

@Injectable()
export class CaregiverNotesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Verify caregiver has access to elder
   */
  private async verifyCaregiverAccess(caregiverUserId: bigint, elderUserId: bigint) {
    const assignment = await this.prisma.elderAssignment.findFirst({
      where: {
        caregiverUserId,
        elderUserId,
      },
    });

    if (!assignment) {
      throw new ForbiddenException('You do not have access to this patient');
    }

    return assignment;
  }

  /**
   * Create a caregiver note
   */
  async create(context: ActorContext, createDto: CreateCaregiverNoteDto) {
    const elderUserId = context.elderUserId;
    const caregiverUserId = context.actorUserId;

    // Verify caregiver has access
    await this.verifyCaregiverAccess(caregiverUserId, elderUserId);

    const note = await this.prisma.caregiverNote.create({
      data: {
        elderUserId,
        caregiverUserId,
        noteText: createDto.noteText,
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
        caregiverUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
      },
    });

    return this.mapToResponse(note);
  }

  /**
   * Find all notes for an elder user
   */
  async findAll(context: ActorContext) {
    const elderUserId = context.elderUserId;
    const caregiverUserId = context.actorUserId;

    // Verify caregiver has access
    await this.verifyCaregiverAccess(caregiverUserId, elderUserId);

    const notes = await this.prisma.caregiverNote.findMany({
      where: {
        elderUserId,
        caregiverUserId, // Only return notes created by this caregiver
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
        caregiverUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
      },
    });

    return notes.map((note) => this.mapToResponse(note));
  }

  /**
   * Find a note by ID
   */
  async findOne(context: ActorContext, noteId: bigint) {
    const caregiverUserId = context.actorUserId;

    const note = await this.prisma.caregiverNote.findFirst({
      where: {
        noteId,
        caregiverUserId, // Only allow access to own notes
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
        caregiverUser: {
          select: {
            userId: true,
            full_name: true,
          },
        },
      },
    });

    if (!note) {
      throw new NotFoundException('Note not found');
    }

    return this.mapToResponse(note);
  }

  /**
   * Delete a note
   */
  async remove(context: ActorContext, noteId: bigint) {
    const caregiverUserId = context.actorUserId;

    const note = await this.prisma.caregiverNote.findFirst({
      where: {
        noteId,
        caregiverUserId, // Only allow deletion of own notes
      },
    });

    if (!note) {
      throw new NotFoundException('Note not found');
    }

    await this.prisma.caregiverNote.delete({
      where: { noteId },
    });

    return { message: 'Note deleted successfully' };
  }

  /**
   * Map database model to API response
   */
  private mapToResponse(note: any) {
    return {
      id: note.noteId.toString(),
      elderUserId: note.elderUserId.toString(),
      caregiverUserId: note.caregiverUserId.toString(),
      text: note.noteText,
      timestamp: note.createdAt.toISOString(),
      updatedAt: note.updatedAt.toISOString(),
      elderName: note.elderUser?.full_name,
      caregiverName: note.caregiverUser?.full_name,
    };
  }
}
