// @ts-nocheck
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        ExtractJwt.fromAuthHeaderAsBearerToken(),
        (req) => {
          if (req.query && req.query.token) {
            return req.query.token as string;
          }
          return null;
        },
      ]),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'default-secret',
    });
  }

  async validate(payload: JwtPayload) {
    const userId = BigInt(payload.sub);

    const user = await this.prisma.user.findUnique({
      where: { userId },
      include: {
        userRoles: {
          include: { role: true },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const dbRole = user.userRoles[0]?.role?.roleCode;
    const activeRole = this.toClientRoleCode(payload.role || dbRole);

    return {
      ...user,
      activeRoleCode: activeRole,
    };
  }

  private toClientRoleCode(roleCode: string | undefined): string {
    if (!roleCode) {
      return 'patient';
    }
    return roleCode.toLowerCase();
  }
}
