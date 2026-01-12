import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';

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
    });
    const normalizedRoles = roles.map((userRole) => userRole.role.roleCode.toLowerCase());
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
    });

    return assignments.map((assignment) => ({
      id: assignment.elderAssignmentId.toString(),
      name: assignment.caregiverUser.full_name,
      phone: assignment.caregiverUser.phone || '',
      status: 'accepted' as const,
      relationship: assignment.relationshipCode,
      linkedPatientId: assignment.elderUserId.toString(),
      invitedAt: assignment.createdAt.toISOString(),
      acceptedAt: assignment.createdAt.toISOString(),
    }));
  }

  /**
   * Get all caregivers across the system with assignment counts
   */
  async findAllCaregivers() {
    const caregivers = await this.prisma.user.findMany({
      where: {
        userRoles: { some: { role: { roleCode: 'caregiver' } } },
      },
      include: {
        elderAssignmentsAsCaregiver: true,
        loginEvents: {
          orderBy: { loginAt: 'desc' },
          take: 1,
        },
      },
    });

    return caregivers.map((caregiver) => ({
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
    });

    return assignments.map((assignment) => ({
      id: assignment.elderAssignmentId.toString(),
      elderId: assignment.elderUser.userId.toString(),
      elderName: assignment.elderUser.full_name,
      elderPhone: assignment.elderUser.phone || '',
      elderEmail: assignment.elderUser.email || '',
      relationship: assignment.relationshipCode,
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

    // Validate that either phone or email is provided
    if (!createDto.phone && !createDto.email) {
      throw new BadRequestException('Either phone or email must be provided');
    }

    // Check if elder user exists
    const elderUser = await this.prisma.user.findUnique({
      where: { userId: elderUserId },
    });

    if (!elderUser) {
      throw new NotFoundException('Elder user not found');
    }

    // Check if invitation already exists by phone or email
    const whereClause: any = {
      elderUserId,
      status: 'pending',
      expiresAt: {
        gt: new Date(),
      },
    };

    // Build OR condition for phone or email
    const orConditions: any[] = [];
    
    if (createDto.phone) {
      orConditions.push({ invitePhone: createDto.phone });
    }
    
    if (createDto.email) {
      orConditions.push({ inviteEmail: createDto.email });
    }

    if (orConditions.length > 0) {
      whereClause.OR = orConditions;
      
      const existingInvitation = await this.prisma.userInvitation.findFirst({
        where: whereClause,
      });

      if (existingInvitation) {
        const identifier = createDto.email || createDto.phone;
        throw new BadRequestException(
          `Invitation already sent to ${identifier}`,
        );
      }
    }

    // Create invitation
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days expiry

    const inviteCode = this.generateInviteCode();
    const invitePhone = createDto.phone || 'email-only'; // Placeholder for email-only invitations

    const invitation = await this.prisma.userInvitation.create({
      data: {
        inviterUserId: userId,
        elderUserId,
        targetRoleCode: 'caregiver',
        relationshipCode: createDto.relationship,
        invitePhone,
        inviteEmail: createDto.email || null,
        inviteCode,
        status: 'pending',
        expiresAt,
      },
    });

    // Send email invitation if email is provided
    if (createDto.email) {
      await this.emailService.sendCaregiverInvitationEmail(
        createDto.email,
        inviteCode,
        elderUser.full_name,
        createDto.relationship,
      );

      // Check if user already exists and create notification
      const existingUser = await this.prisma.user.findUnique({
        where: { email: createDto.email },
        include: {
          userRoles: {
            include: {
              role: true,
            },
          },
        },
      });

      if (existingUser) {
        const hasCaregiverRole = existingUser.userRoles.some(
          (ur) => ur.role.roleCode.toLowerCase() === 'caregiver',
        );

        if (hasCaregiverRole) {
          // Create notification for existing caregiver
          await this.prisma.notification.create({
            data: {
              userId: existingUser.userId,
              title: 'New Caregiver Invitation',
              message: `${elderUser.full_name} has invited you to be their caregiver`,
              notificationType: 'caregiver_invitation',
              actionData: {
                invitationId: invitation.invitationId.toString(),
                inviteCode: invitation.inviteCode,
                patientName: elderUser.full_name,
                elderUserId: elderUserId.toString(),
                relationship: invitation.relationshipCode,
              },
              isRead: false,
              isSent: true,
              status: 'sent',
            },
          });
        }
      }
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
   * Get invitation by code
   */
  async getInvitationByCode(inviteCode: string) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: {
        inviteCode,
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
            phone: true,
          },
        },
      },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Invitation already processed');
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('Invitation has expired');
    }

    return {
      id: invitation.invitationId.toString(),
      phone: invitation.invitePhone,
      inviteCode: invitation.inviteCode,
      status: invitation.status,
      expiresAt: invitation.expiresAt.toISOString(),
      relationship: invitation.relationshipCode,
      elderUser: {
        id: invitation.elderUser.userId.toString(),
        name: invitation.elderUser.full_name,
        phone: invitation.elderUser.phone,
      },
    };
  }

  /**
   * Accept invitation
   */
  async acceptInvitation(userId: bigint, invitationId: bigint) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: {
        invitationId,
      },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Invitation already processed');
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('Invitation has expired');
    }

    // Update invitation
    await this.prisma.userInvitation.update({
      where: { invitationId },
      data: {
        status: 'accepted',
        acceptedUserId: userId,
        acceptedAt: new Date(),
      },
    });

    // Create elder assignment
    const assignment = await this.prisma.elderAssignment.create({
      data: {
        elderUserId: invitation.elderUserId,
        caregiverUserId: userId,
        relationshipCode: invitation.relationshipCode,
        isPrimary: false,
      },
      include: {
        caregiverUser: {
          select: {
            userId: true,
            full_name: true,
            phone: true,
          },
        },
      },
    });

    return {
      id: assignment.elderAssignmentId.toString(),
      name: assignment.caregiverUser.full_name,
      phone: assignment.caregiverUser.phone || '',
      status: 'accepted' as const,
      relationship: assignment.relationshipCode,
      linkedPatientId: assignment.elderUserId.toString(),
      invitedAt: invitation.createdAt.toISOString(),
      acceptedAt: invitation.acceptedAt?.toISOString() || new Date().toISOString(),
    };
  }

  /**
   * Get pending invitations for logged-in caregiver
   * Uses notifications table to find invitations sent to this caregiver
   */
  async getPendingInvitationsForCaregiver(userId: bigint) {
    // Query notifications with type 'caregiver_invitation' for this user
    const notifications = await this.prisma.notification.findMany({
      where: {
        userId,
        notificationType: 'caregiver_invitation',
        isRead: false,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Extract invitation IDs from actionData and fetch invitation details
    const invitationIds = notifications
      .map((n) => {
        const actionData = n.actionData as any;
        return actionData?.invitationId;
      })
      .filter((id) => id != null)
      .map((id) => BigInt(id));

    if (invitationIds.length === 0) {
      return [];
    }

    // Fetch invitations and verify they're still pending
    const invitations = await this.prisma.userInvitation.findMany({
      where: {
        invitationId: { in: invitationIds },
        status: 'pending',
        expiresAt: { gt: new Date() },
      },
      include: {
        elderUser: {
          select: {
            userId: true,
            full_name: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return invitations.map((inv) => ({
      id: inv.invitationId.toString(),
      inviteCode: inv.inviteCode,
      patientName: inv.elderUser.full_name,
      patientId: inv.elderUserId.toString(),
      relationship: inv.relationshipCode,
      expiresAt: inv.expiresAt.toISOString(),
      createdAt: inv.createdAt.toISOString(),
      notificationId: notifications.find(
        (n) =>
          (n.actionData as any)?.invitationId === inv.invitationId.toString(),
      )?.notificationId.toString(),
    }));
  }

  /**
   * Accept invitation by code
   */
  async acceptInvitationByCode(userId: bigint, inviteCode: string) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: { inviteCode },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Invitation already processed');
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('Invitation has expired');
    }

    // Verify user matches invitation (by email/phone)
    const user = await this.prisma.user.findUnique({
      where: { userId },
      select: { email: true, phone: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if invitation was sent to this user
    // For email invitations, invitePhone is 'email-only', so we check notifications
    const notifications = await this.prisma.notification.findMany({
      where: {
        userId,
        notificationType: 'caregiver_invitation',
      },
    });

    // Check if any notification has this inviteCode in actionData
    const notification = notifications.find((n) => {
      const actionData = n.actionData as any;
      return actionData?.inviteCode === inviteCode;
    });

    const matches =
      user.phone === invitation.invitePhone ||
      invitation.invitePhone === 'email-only' ||
      notification !== undefined;

    if (!matches) {
      throw new BadRequestException(
        'This invitation was not sent to your account',
      );
    }

    // Use existing acceptInvitation logic
    const result = await this.acceptInvitation(
      userId,
      invitation.invitationId,
    );

    // Mark related notification as read
    if (notification) {
      await this.prisma.notification.update({
        where: { notificationId: notification.notificationId },
        data: { isRead: true },
      });
    }

    return result;
  }

  /**
   * Decline invitation
   */
  async declineInvitation(userId: bigint, invitationId: bigint) {
    const invitation = await this.prisma.userInvitation.findUnique({
      where: {
        invitationId,
      },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('Invitation already processed');
    }

    await this.prisma.userInvitation.update({
      where: { invitationId },
      data: {
        status: 'declined',
      },
    });

    return { message: 'Invitation declined successfully' };
  }

  /**
   * Remove caregiver assignment
   */
  async remove(userId: bigint, assignmentId: bigint) {
    const assignment = await this.prisma.elderAssignment.findFirst({
      where: {
        elderAssignmentId: assignmentId,
        elderUserId: userId,
      },
    });

    if (!assignment) {
      throw new NotFoundException('Caregiver assignment not found');
    }

    await this.prisma.elderAssignment.delete({
      where: { elderAssignmentId: assignmentId },
    });

    return { message: 'Caregiver removed successfully' };
  }
}

