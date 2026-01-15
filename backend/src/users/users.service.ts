import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) { }

  async getProfile(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { userId },
      include: {
        subscriptions: {
          where: { status: 'active' },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
        userRoles: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: {
            role: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate age from dob
    const age = user.dob
      ? Math.floor((new Date().getTime() - new Date(user.dob).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
      : null;

    // Get subscription tier
    const subscriptionTier = user.subscriptions[0]?.planId
      ? await this.prisma.subscriptionPlan.findUnique({
        where: { planId: user.subscriptions[0].planId },
      })
      : null;

    const activeRoleCode = user.userRoles[0]?.role?.roleCode;
    const normalizedRole = activeRoleCode
      ? activeRoleCode.toLowerCase()
      : 'patient';

    return {
      id: user.userId.toString(),
      email: user.email || '',
      name: user.full_name,
      role: normalizedRole,
      subscriptionTier: subscriptionTier?.planCode || 'free',
      age: age?.toString() || null,
      medicalConditions: user.medicalConditions || null,
      emergencyContact: user.emergencyContact || null,
      phone: user.phone || null,
      avatarUrl: user.avatarUrl || null,
    };
  }

  async getUserById(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate age from dob
    const age = user.dob
      ? Math.floor((new Date().getTime() - new Date(user.dob).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
      : null;

    return {
      id: user.userId.toString(),
      email: user.email || null,
      name: user.full_name,
      phone: user.phone || null,
      dob: user.dob ? user.dob.toISOString().split('T')[0] : null,
      age: age?.toString() || null,
      avatarUrl: user.avatarUrl || null,
      gender: user.gender || null,
      address: user.address || null,
      medicalConditions: user.medicalConditions || null,
      emergencyContact: user.emergencyContact || null,
    };
  }

  async getPatientsList(user: any) {
    const actorUserId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    const role = (user.role || user.activeRoleCode || 'patient').toString().toLowerCase();

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7);

    const privilegedRoles = ['super_admin', 'admin', 'clinician', 'coordinator', 'provider'];

    // Define filtering based on role
    let whereClause: any = {
      userRoles: { some: { role: { roleCode: 'patient' } } },
    };

    if (!privilegedRoles.includes(role)) {
      if (role === 'caregiver') {
        whereClause = {
          ...whereClause,
          elderAssignmentsAsElder: {
            some: { caregiverUserId: actorUserId },
          },
        };
      } else if (role === 'patient') {
        whereClause = {
          ...whereClause,
          userId: actorUserId,
        };
      } else {
        // Unknown role or restricted role
        return [];
      }
    }

    const patients = await this.prisma.user.findMany({
      where: whereClause,
      include: {
        vitalMeasurements: {
          where: { recordedAt: { gte: cutoff } },
          orderBy: { recordedAt: 'desc' },
        },
        userDocuments: true,
        elderAssignmentsAsElder: {
          include: {
            caregiverUser: {
              select: { full_name: true },
            },
          },
        },
        loginEvents: {
          orderBy: { loginAt: 'desc' },
          take: 1,
        },
        subscriptions: {
          where: { status: 'active' },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    const planIds = Array.from(
      new Set(
        patients
          .map((p) => p.subscriptions[0]?.planId?.toString())
          .filter(Boolean) as string[],
      ),
    );

    const planLookup =
      planIds.length > 0
        ? await this.prisma.subscriptionPlan.findMany({
          where: { planId: { in: planIds.map((id) => BigInt(id)) } },
        })
        : [];

    const planMap = new Map<string, string>();
    for (const plan of planLookup) {
      const code = plan.planCode.toUpperCase();
      planMap.set(plan.planId.toString(), code === 'PREMIUM' ? 'Premium' : 'Essential');
    }

    const results = await Promise.all(
      patients.map(async (patient) => {
        const medIntakes = await this.prisma.medIntake.findMany({
          where: {
            schedule: {
              medication: {
                elderUserId: patient.userId,
              },
            },
            dueAt: { gte: cutoff },
          },
        });

        const adherence =
          medIntakes.length === 0
            ? 100
            : Math.round(
              (medIntakes.filter((i) => i.status === 'taken').length /
                medIntakes.length) *
              100,
            );

        const alerts = patient.vitalMeasurements.filter((m) =>
          this.isAbnormal(m),
        ).length;

        const age = patient.dob
          ? Math.floor(
            (new Date().getTime() - new Date(patient.dob).getTime()) /
            (365.25 * 24 * 60 * 60 * 1000),
          )
          : null;

        const plan =
          patient.subscriptions[0]?.planId &&
            planMap.get(patient.subscriptions[0].planId.toString())
            ? planMap.get(patient.subscriptions[0].planId.toString())
            : 'Essential';

        const latestActivity = this.getLatestActivity(
          patient.loginEvents?.[0]?.loginAt,
          patient.vitalMeasurements?.[0]?.recordedAt,
        );

        return {
          id: patient.userId.toString(),
          name: patient.full_name,
          slug: this.slugify(patient.full_name),
          age: age ?? null,
          risk: alerts > 0 ? 'high' : patient.vitalMeasurements.length ? 'moderate' : 'low',
          adherence,
          alerts,
          unreadDocs: patient.userDocuments.length,
          subscription: plan,
          careTeam: patient.elderAssignmentsAsElder.map(
            (assignment) => assignment.caregiverUser.full_name,
          ),
          lastActivity: latestActivity,
        };
      }),
    );

    return results;
  }

  private slugify(input: string): string {
    return input
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  private getLatestActivity(...timestamps: Array<Date | null | undefined>) {
    const validDates = timestamps.filter(Boolean) as Date[];
    if (validDates.length === 0) {
      return null;
    }
    const latest = validDates.reduce((a, b) => (a > b ? a : b));
    return latest.toISOString();
  }

  private isAbnormal(measurement: any): boolean {
    const kindCode = measurement.kindCode?.toLowerCase();
    const value1 = measurement.value1 ? parseFloat(measurement.value1.toString()) : null;
    const value2 = measurement.value2 ? parseFloat(measurement.value2.toString()) : null;

    if (kindCode === 'bp' && value1 && value2) {
      return value1 > 140 || value1 < 80 || value2 > 90 || value2 < 50;
    }
    if (kindCode === 'bs' && value1 !== null) {
      return value1 > 125 || value1 < 60;
    }
    if (kindCode === 'hr' && value1 !== null) {
      return value1 < 50 || value1 > 110;
    }
    if (kindCode === 'temp' && value1 !== null) {
      return value1 < 96.0 || value1 > 100.4;
    }
    if (kindCode === 'o2' && value1 !== null) {
      return value1 < 90;
    }
    return false;
  }

  async updateProfile(userId: bigint, updateProfileDto: UpdateProfileDto) {
    try {
      const updateData: any = {};
      if (updateProfileDto.name) updateData.full_name = updateProfileDto.name;
      if (updateProfileDto.phoneNumber) updateData.phone = updateProfileDto.phoneNumber;
      if (updateProfileDto.dateOfBirth) updateData.dob = new Date(updateProfileDto.dateOfBirth);
      if (updateProfileDto.address) updateData.address = updateProfileDto.address;
      // Note: Database schema doesn't have separate city/country fields, combining into address
      if (updateProfileDto.city || updateProfileDto.country) {
        const parts = [updateProfileDto.address || updateData.address, updateProfileDto.city, updateProfileDto.country].filter(Boolean);
        updateData.address = parts.join(', ');
      }
      if (updateProfileDto.medicalConditions !== undefined)
        updateData.medicalConditions = updateProfileDto.medicalConditions;
      if (updateProfileDto.emergencyContact !== undefined)
        updateData.emergencyContact = updateProfileDto.emergencyContact;

      const user = await this.prisma.user.update({
        where: { userId },
        data: updateData,
      });

      return this.getProfile(userId);
    } catch (error: any) {
      console.error('Profile update error:', error);
      if (error?.code === 'P2002') {
        throw new ConflictException('Phone number already exists');
      }
      throw error;
    }
  }

  async completeProfile(userId: bigint, completeProfileDto: CompleteProfileDto) {
    const updateData: any = {
      full_name: completeProfileDto.name,
      phone: completeProfileDto.phoneNumber,
      dob: completeProfileDto.dateOfBirth ? new Date(completeProfileDto.dateOfBirth) : null,
      address: completeProfileDto.address || null,
    };

    const user = await this.prisma.user.update({
      where: { userId },
      data: updateData,
    });

    return {
      message: 'Profile completed successfully',
      user: await this.getProfile(userId),
    };
  }
}
