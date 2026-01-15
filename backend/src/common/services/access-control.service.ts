import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface ActorContext {
  actorUserId: bigint;
  actorRole: string;
  elderUserId: bigint;
}

@Injectable()
export class AccessControlService {
  constructor(private prisma: PrismaService) { }

  /**
   * Resolve the acting user (caregiver/patient) and target elder context.
   * Throws when caregivers lack assignment or when patients target others.
   */
  async resolveActorContext(
    user: any,
    requestedElderUserId?: string,
  ): Promise<ActorContext> {
    if (!user?.userId) {
      throw new ForbiddenException('User context is not available.');
    }

    const actorUserId =
      typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    const role = (user.activeRoleCode || 'patient').toString().toLowerCase();
    const privilegedRoles = ['super_admin', 'admin', 'provider', 'clinician', 'coordinator'];

    if (privilegedRoles.includes(role)) {
      const elderUserId = requestedElderUserId
        ? BigInt(String(requestedElderUserId))
        : actorUserId;

      return {
        actorUserId,
        actorRole: role,
        elderUserId,
      };
    }

    if (role === 'caregiver') {
      if (!requestedElderUserId) {
        throw new BadRequestException('Caregiver must specify an elderUserId.');
      }

      // Ensure requestedElderUserId is converted to string if it's a number
      const elderUserIdStr = String(requestedElderUserId);
      const elderUserId = BigInt(elderUserIdStr);

      const assignment = await this.prisma.elderAssignment.findFirst({
        where: {
          caregiverUserId: actorUserId,
          elderUserId,
        },
      });

      if (!assignment) {
        throw new ForbiddenException(
          'Caregiver is not assigned to the requested elder.',
        );
      }

      return {
        actorUserId,
        actorRole: role,
        elderUserId,
      };
    }

    if (requestedElderUserId) {
      // Ensure requestedElderUserId is converted to string if it's a number
      const elderUserIdStr = String(requestedElderUserId);
      const elderUserId = BigInt(elderUserIdStr);
      if (elderUserId !== actorUserId) {
        throw new ForbiddenException(
          'Patients are not allowed to access other user records.',
        );
      }
    }

    return {
      actorUserId,
      actorRole: role,
      elderUserId: actorUserId,
    };
  }
}

