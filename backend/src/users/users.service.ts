// @ts-nocheck
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { getPKTDate } from '../common/utils/date-utils';
import * as bcrypt from 'bcrypt';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) { }

  private _formatAvatarUrl(avatarUrl?: string, baseUrl?: string): string | null {
    if (!avatarUrl) return null;
    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (baseUrl && avatarUrl.startsWith('/')) return `${baseUrl}${avatarUrl}`;
    return avatarUrl;
  }

  async getProfile(userId: bigint, baseUrl?: string) {
    const user = await this.prisma.user.findUnique({
      where: { userId },
      include: {
        subscriptions: {
          where: { status: 'active' },
          orderBy: { createdAt: 'desc' },
          take: 1
        },
        userRoles: {
          include: {
            role: true
          }
        }
      } as any
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Cast user to any to bypass Prisma type mismatch
    const u = user as any;
    
    return {
      userId: u.userId.toString(),
      email: u.email,
      phone: u.phone,
      fullName: u.full_name,
      avatarUrl: this._formatAvatarUrl(u.avatarUrl, baseUrl),
      status: u.status,
      isProfileComplete: u.is_profile_complete,
      roles: u.userRoles.map((ur: any) => ur.role.roleCode),
      subscription: u.subscriptions?.[0] ? {
        planId: u.subscriptions[0].planId,
        status: u.subscriptions[0].status,
        expiresAt: u.subscriptions[0].expiresAt
      } : null,
      medicineRemindersEnabled: u.medicineRemindersEnabled,
      healthAlertsEnabled: u.healthAlertsEnabled,
      caregiverUpdatesEnabled: u.caregiverUpdatesEnabled,
      biometricEnabled: u.biometricEnabled,
    };
  }

  async updateProfile(userId: bigint, updateDto: UpdateProfileDto, baseUrl?: string) {
    const data: any = {};
    if (updateDto.fullName) data.full_name = updateDto.fullName;
    if (updateDto.profilePicture) data.avatarUrl = updateDto.profilePicture;
    
    // Add new settings fields
    if (updateDto.medicineRemindersEnabled !== undefined) {
      data.medicineRemindersEnabled = updateDto.medicineRemindersEnabled;
    }
    if (updateDto.healthAlertsEnabled !== undefined) {
      data.healthAlertsEnabled = updateDto.healthAlertsEnabled;
    }
    if (updateDto.caregiverUpdatesEnabled !== undefined) {
      data.caregiverUpdatesEnabled = updateDto.caregiverUpdatesEnabled;
    }
    if (updateDto.biometricEnabled !== undefined) {
      data.biometricEnabled = updateDto.biometricEnabled;
    }

    data.updatedAt = getPKTDate();

    const user = await this.prisma.user.update({
      where: { userId },
      data,
      include: {
        subscriptions: {
          where: { status: 'active' },
          orderBy: { createdAt: 'desc' },
          take: 1
        },
        userRoles: {
          include: {
            role: true
          }
        }
      } as any
    });

    const u = user as any;

    return {
      userId: u.userId.toString(),
      fullName: u.full_name,
      avatarUrl: this._formatAvatarUrl(u.avatarUrl, baseUrl),
      roles: u.userRoles.map((ur: any) => ur.role.roleCode),
      subscription: u.subscriptions?.[0] ? {
        planId: u.subscriptions[0].planId,
        status: u.subscriptions[0].status
      } : null,
      medicineRemindersEnabled: u.medicineRemindersEnabled,
      healthAlertsEnabled: u.healthAlertsEnabled,
      caregiverUpdatesEnabled: u.caregiverUpdatesEnabled,
      biometricEnabled: u.biometricEnabled,
    };
  }

  async completeProfile(userId: bigint, completeDto: CompleteProfileDto) {
    const user = await this.prisma.user.update({
      where: { userId },
      data: {
        full_name: completeDto.fullName,
        is_profile_complete: true,
        updatedAt: getPKTDate(),
      },
    });

    return {
      userId: user.userId.toString(),
      fullName: user.full_name,
      isProfileComplete: user.is_profile_complete,
    };
  }

  async getPatientsList(userId: bigint) {
    // A caregiver can see patients they are assigned to
    const assignments = await this.prisma.elderAssignment.findMany({
      where: {
        caregiverUserId: userId,
        isActive: true,
      },
      include: {
        elderUser: {
          include: {
            subscriptions: {
              where: { status: 'active' },
              orderBy: { createdAt: 'desc' },
              take: 1
            }
          }
        }
      } as any
    });

    return Promise.all(assignments.map(async (assignment: any) => {
      const patient = assignment.elderUser;
      
      // Get recent health score (vitals average)
      const vitals = await this.prisma.vitalMeasurement.findMany({
        where: {
          elderUserId: patient.userId,
          recordedAt: {
            gte: new Date(Date.now() - 24 * 60 * 60 * 1000) // Last 24 hours
          }
        },
        orderBy: { recordedAt: 'desc' }
      });

      // Get recent medication count
      const medIntake = await this.prisma.medIntake.findMany({
        where: {
          schedule: {
            medication: {
              elderUserId: patient.userId
            }
          },
          dueAt: {
            gte: getPKTDate(getPKTDate().setHours(0, 0, 0, 0)),
            lte: getPKTDate(getPKTDate().setHours(23, 59, 59, 999))
          }
        } as any
      });

      const taken = medIntake.filter((i: any) => i.status === 'taken').length;
      const total = medIntake.length;

      return {
        userId: patient.userId.toString(),
        fullName: patient.full_name,
        profilePicture: patient.profile_picture,
        relationship: assignment.relationshipCode,
        healthScore: vitals.length > 0 ? 85 : 0, // Mock logic for now
        medicationProgress: total > 0 ? taken / total : 1.0,
        isSubscriptionActive: patient.subscriptions?.length > 0,
        planId: patient.subscriptions?.[0]?.planId || 'free'
      };
    }));
  }

  async uploadAvatar(userId: bigint, file: any, baseUrl: string) {
    const avatarDir = path.join(process.cwd(), 'uploads', 'avatars');
    if (!fs.existsSync(avatarDir)) {
      fs.mkdirSync(avatarDir, { recursive: true });
    }

    const fileName = `${userId}_${Date.now()}${path.extname(file.originalname)}`;
    const filePath = path.join(avatarDir, fileName);

    fs.writeFileSync(filePath, file.buffer);

    // Use absolute URL for the mobile app
    // In production, this should be the base URL + /uploads/...
    // For now, we return the relative path which the mobile app can prefix if needed
    // However, the mobile app expects a full URL usually from CachedNetworkImage
    const avatarUrl = `/uploads/avatars/${fileName}`;

    await this.prisma.user.update({
      where: { userId },
      data: {
        avatarUrl,
        updatedAt: getPKTDate(),
      },
    });

    return this.getProfile(userId, baseUrl);
  }

  async changePassword(userId: bigint, changePasswordDto: ChangePasswordDto) {
    const { oldPassword, newPassword, confirmPassword } = changePasswordDto;

    if (newPassword !== confirmPassword) {
      throw new ConflictException('New passwords do not match');
    }

    const user = await this.prisma.user.findUnique({
      where: { userId },
    });

    if (!user || !user.passwordHash) {
      throw new NotFoundException('User not found');
    }

    const isPasswordValid = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isPasswordValid) {
      throw new ConflictException('Invalid current password');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { userId },
      data: {
        passwordHash: hashedPassword,
        updatedAt: getPKTDate(),
      },
    });

    return { message: 'Password changed successfully' };
  }
}
