// @ts-nocheck
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';
import { ContactCaregiverDto } from './dto/contact-caregiver.dto';
import { getPKTDate } from '../common/utils/date-utils';

@Injectable()
export class CaregiversService {
  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
  ) {}

  /**
   * Generate unique invitation code
   */
  private generateInviteCode(): string {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
  }

  /**
   * Get all caregivers (elder assignments) for a user
   */
  async findAll(userId: bigint) {
    const roles = await this.prisma.userRole.findMany({
      where: { userId },
      include: { role: true },
    } as any);
    const normalizedRoles = roles.map((userRole: any) => userRole.role.roleCode.toLowerCase());
    const hasCaregiverRole = normalizedRoles.includes('caregiver');
    const hasPatientRole = normalizedRoles.includes('patient');

    if (hasCaregiverRole && !hasPatientRole) {
      return this.findAssignmentsForCaregiver(userId);
    }

    const assignments = await this.prisma.elderAssignment.findMany({
      where: {
        elderUserId: userId,
      },
      include: {
        caregiverUser: {
          select: {
            userId: true,
            full_name: true,
            phone: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    } as any);

    return assignments.map((assignment: any) => ({
      id: assignment.elderAssignmentId.toString(),
      name: assignment.caregiverUser.full_name,
      phone: assignment.caregiverUser.phone || '',
      status: 'accepted' as const,
      relationship: assignment.relationshipCode,
      isActive: assignment.isActive,
    }));
  }

  /**
   * Get all elder assignments for a caregiver user
   */
  async findAssignmentsForCaregiver(userId: bigint) {
    const assignments = await this.prisma.elderAssignment.findMany({
      where: {
        caregiverUserId: userId,
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
            phone: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    } as any);

    return assignments.map((assignment: any) => ({
      id: assignment.elderAssignmentId.toString(),
      elderId: assignment.elderUser.userId.toString(),
      elderName: assignment.elderUser.full_name,
      elderPhone: assignment.elderUser.phone || '',
      elderEmail: assignment.elderUser.email || '',
      relationship: assignment.relationshipCode,
      isActive: assignment.isActive,
      linkedPatientId: assignment.elderUserId.toString(),
      invitedAt: assignment.createdAt.toISOString(),
      acceptedAt: assignment.createdAt.toISOString(),
    }));
  }

  /**
   * Send caregiver invitation
   */
  async sendInvitation(userId: bigint, createDto: CreateInvitationDto) {
    const elderUserId = createDto.elderUserId ? BigInt(createDto.elderUserId) : userId;

    // Check if assignment already exists
    const existingAssignment = await this.prisma.elderAssignment.findFirst({
      where: {
        elderUserId,
        caregiverUser: {
          OR: [
            { email: createDto.email || undefined },
            { phone: createDto.phone || undefined },
          ],
        },
      },
    });

    if (existingAssignment) {
      throw new BadRequestException('Caregiver is already assigned to this patient');
    }

    // Check if user exists
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: createDto.email || undefined },
          { phone: createDto.phone || undefined },
        ],
      },
      include: {
        userRoles: {
          include: {
            role: true,
          },
        },
      } as any,
    });

    if (existingUser) {
      const isCaregiver = (existingUser as any).userRoles.some(
        (ur: any) => ur.role.roleCode.toLowerCase() === 'caregiver',
      );

      // If existing user is not a caregiver, add the role
      if (!isCaregiver) {
        // Find caregiver role
        const caregiverRole = await this.prisma.role.findFirst({
          where: { roleCode: 'caregiver' },
        });

        if (caregiverRole) {
          await this.prisma.userRole.create({
            data: {
              userId: existingUser.userId,
              roleId: caregiverRole.roleId,
              createdAt: getPKTDate(),
            },
          });
        }
      }

      // Create assignment directly
      const assignment = await this.prisma.elderAssignment.create({
        data: {
          elderUserId,
          caregiverUserId: existingUser.userId,
          relationshipCode: createDto.relationship || 'other',
          isActive: true,
          createdAt: getPKTDate(),
          updatedAt: getPKTDate(),
        },
      });

      // Notify the caregiver
      await this.prisma.notification.create({
        data: {
          userId: existingUser.userId,
          title: 'New Patient Link',
          message: `You have been linked as a caregiver for a new patient.`,
          notificationType: 'patient_link',
          actionData: {
            elderAssignmentId: assignment.elderAssignmentId.toString(),
            elderUserId: elderUserId.toString(),
          },
          isRead: false,
          isSent: true,
          status: 'sent',
          createdAt: getPKTDate(),
          updatedAt: getPKTDate(),
        },
      });

      return {
        id: assignment.elderAssignmentId.toString(),
        name: existingUser.full_name,
        phone: existingUser.phone || '',
        email: existingUser.email || '',
        status: 'accepted' as const,
        relationship: assignment.relationshipCode,
        isActive: assignment.isActive,
      };
    }

    // User doesn't exist, create invitation
    const invitation = await this.prisma.userInvitation.create({
      data: {
        inviterUserId: userId,
        elderUserId,
        inviteEmail: createDto.email || null,
        invitePhone: createDto.phone || null,
        inviteCode: this.generateInviteCode(),
        relationshipCode: createDto.relationship || 'other',
        status: 'pending',
        expiresAt: getPKTDate(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        createdAt: getPKTDate(),
      },
      include: {
        inviterUser: true,
      } as any,
    });

    // Send email invitation if email is provided
    if (createDto.email) {
      const inviterName = (invitation as any).inviterUser?.full_name || 'A patient';
      await this.emailService.sendCaregiverInvitationEmail(
        createDto.email,
        invitation.inviteCode,
        inviterName,
        createDto.relationship,
      );
    }

    return {
      id: invitation.invitationId.toString(),
      phone: invitation.invitePhone,
      email: createDto.email,
      inviteCode: invitation.inviteCode,
      status: invitation.status,
      expiresAt: invitation.expiresAt.toISOString(),
      relationship: invitation.relationshipCode,
    };
  }

  /**
   * Get all pending invitations
   */
  async getInvitations(userId: bigint) {
    const invitations = await this.prisma.userInvitation.findMany({
      where: {
        inviterUserId: userId,
        status: 'pending',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return invitations.map((invitation) => ({
      id: invitation.invitationId.toString(),
      phone: invitation.invitePhone,
      inviteCode: invitation.inviteCode,
      status: invitation.status,
      expiresAt: invitation.expiresAt.toISOString(),
      relationship: invitation.relationshipCode,
      elderUserId: invitation.elderUserId.toString(),
    }));
  }

  /**
   * Get pending invitations for caregiver
   */
  async getPendingInvitationsForCaregiver(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { userId },
    });

    if (!user || (!user.email && !user.phone)) {
      return [];
    }

    const invitations = await this.prisma.userInvitation.findMany({
      where: {
        OR: [
          ...(user.email ? [{ inviteEmail: user.email }] : []),
          ...(user.phone ? [{ invitePhone: user.phone }] : []),
        ],
        status: 'pending',
      } as any,
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        inviterUser: true,
        elderUser: true,
      } as any,
    });

    return invitations.map((inv) => ({
      id: inv.invitationId.toString(),
      inviterName: inv.inviterUser?.full_name || 'Someone',
      elderName: inv.elderUser?.full_name || 'Patient',
      relationship: inv.relationshipCode,
      createdAt: inv.createdAt.toISOString(),
      inviteCode: inv.inviteCode,
    }));
  }

  /**
   * Get invitation by code
   */
  async getInvitationByCode(code: string) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: { inviteCode: code },
      include: {
        inviterUser: true,
        elderUser: true,
      } as any,
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    return {
      id: invitation.invitationId.toString(),
      inviterName: invitation.inviterUser?.full_name || 'Someone',
      elderName: invitation.elderUser?.full_name || 'Patient',
      relationship: invitation.relationshipCode,
      status: invitation.status,
      elderUser: invitation.elderUser,
    };
  }

  /**
   * Accept invitation
   */
  async acceptInvitation(userId: bigint, invitationId: bigint) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: { invitationId },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    // Create assignment
    await this.prisma.elderAssignment.create({
      data: {
        elderUserId: invitation.elderUserId,
        caregiverUserId: userId,
        relationshipCode: invitation.relationshipCode,
        isActive: true,
      },
    });

    // Update invitation status
    await this.prisma.userInvitation.update({
      where: { invitationId },
      data: { status: 'accepted' },
    });

    return { message: 'Invitation accepted successfully' };
  }

  /**
   * Accept invitation by code
   */
  async acceptInvitationByCode(userId: bigint, code: string) {
    const invitation = await this.getInvitationByCode(code);
    return this.acceptInvitation(userId, BigInt(invitation.id));
  }

  /**
   * Decline invitation
   */
  async declineInvitation(userId: bigint, invitationId: bigint) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: { invitationId },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    await this.prisma.userInvitation.update({
      where: { invitationId },
      data: { status: 'declined' },
    });

    return { message: 'Invitation declined successfully' };
  }

  /**
   * Toggle caregiver status (active/inactive)
   */
  async toggleStatus(
    userId: bigint,
    assignmentId: bigint,
    isActive: boolean,
  ) {
    console.log('[DEBUG] CaregiversService.toggleStatus:', {
      userId: userId.toString(),
      assignmentId: assignmentId.toString(),
      isActive
    });

    const assignment = await this.prisma.elderAssignment.findUnique({
      where: {
        elderAssignmentId: assignmentId,
      },
      include: {
        caregiverUser: true,
      } as any,
    });

    if (!assignment) {
      console.log('[DEBUG] Assignment not found:', assignmentId.toString());
      throw new NotFoundException('Caregiver assignment not found');
    }

    // Verify ownership
    if (assignment.elderUserId !== userId) {
      console.log('[DEBUG] Ownership mismatch:', {
        assignmentElderId: assignment.elderUserId.toString(),
        requestUserId: userId.toString()
      });
      throw new BadRequestException('You are not authorized to manage this caregiver');
    }

    const updated = await this.prisma.elderAssignment.update({
      where: {
        elderAssignmentId: assignmentId,
      },
      data: {
        isActive,
      },
    });

    console.log('[DEBUG] Update result:', updated);

    // Send email notification
    if (isActive && (assignment as any).caregiverUser.email) {
      await this.emailService.sendCaregiverActivatedEmail(
        (assignment as any).caregiverUser.email,
        (assignment as any).caregiverUser.full_name,
      );
    } else if (!isActive && (assignment as any).caregiverUser.email) {
      await this.emailService.sendCaregiverDeactivatedEmail(
        (assignment as any).caregiverUser.email,
        (assignment as any).caregiverUser.full_name,
      );
    }

    return {
      success: true,
      isActive: updated.isActive,
    };
  }

  /**
   * Delete caregiver assignment
   */
  async remove(userId: bigint, assignmentId: bigint) {
    const assignment = await this.prisma.elderAssignment.findUnique({
      where: {
        elderAssignmentId: assignmentId,
      },
      include: {
        caregiverUser: true,
      } as any,
    });

    if (!assignment) {
      throw new NotFoundException('Caregiver assignment not found');
    }

    if (assignment.elderUserId !== userId) {
      throw new BadRequestException('You are not authorized to remove this caregiver');
    }

    await this.prisma.elderAssignment.delete({
      where: {
        elderAssignmentId: assignmentId,
      },
    });

    // Send email notification
    if ((assignment as any).caregiverUser.email) {
      await this.emailService.sendCaregiverDeactivatedEmail(
        (assignment as any).caregiverUser.email,
        (assignment as any).caregiverUser.full_name,
      );
    }

    return { success: true };
  }

  /**
   * Find all caregivers
   */
  async findAllCaregivers() {
    const caregivers = await this.prisma.user.findMany({
      where: {
        userRoles: {
          some: {
            role: {
              roleCode: 'caregiver',
            },
          },
        },
      },
      include: {
        elderAssignmentsAsCaregiver: true,
        loginEvents: {
          orderBy: { loginAt: 'desc' },
          take: 1,
        },
      } as any,
    });

    return caregivers.map((caregiver: any) => ({
      id: caregiver.userId.toString(),
      name: caregiver.full_name,
      status: 'active' as const,
      assignments: caregiver.elderAssignmentsAsCaregiver.length,
      escalations: 0,
      lastInteraction:
        caregiver.loginEvents[0]?.loginAt?.toISOString() ||
        caregiver.updatedAt.toISOString(),
      notes: caregiver.status || '',
    }));
  }

  /**
   * Contact caregiver via email
   */
  async contactCaregiver(
    userId: bigint,
    assignmentId: bigint,
    contactDto: ContactCaregiverDto,
  ) {
    const assignment = await this.prisma.elderAssignment.findUnique({
      where: {
        elderAssignmentId: assignmentId,
      },
      include: {
        caregiverUser: true,
        elderUser: true,
      } as any,
    });

    if (!assignment) {
      throw new NotFoundException('Caregiver assignment not found');
    }

    // Verify ownership (only the patient or the patient's admin can send)
    if (assignment.elderUserId !== userId) {
      throw new BadRequestException('You are not authorized to contact this caregiver');
    }

    const caregiver = (assignment as any).caregiverUser;
    const patientName = (assignment as any).elderUser?.full_name || 'Your patient';

    if (!caregiver.email) {
      throw new BadRequestException('Caregiver does not have an email address');
    }

    const success = await this.emailService.sendCaregiverContactEmail(
      caregiver.email,
      patientName,
      contactDto.message,
      contactDto.subject,
    );

    if (!success) {
      throw new BadRequestException('Failed to send email to caregiver');
    }

    return { success: true, message: 'Message sent to caregiver successfully' };
  }

  /**
   * Remove/Cancel caregiver invitation
   */
  async removeInvitation(userId: bigint, invitationId: bigint) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: { invitationId },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.inviterUserId !== userId) {
      throw new BadRequestException('You are not authorized to cancel this invitation');
    }

    await this.prisma.userInvitation.delete({
      where: { invitationId },
    });

    return { success: true };
  }
}
