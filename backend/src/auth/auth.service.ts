import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { User } from '@prisma/client';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
  ) { }

  async register(registerDto: RegisterDto) {
    const {
      email,
      password,
      name,
      phone,
      roleCode: rawRoleCode,
      caregiverInviteCode,
    } = registerDto;

    const normalizedRoleCode = (rawRoleCode || 'patient').trim().toLowerCase();
    const inviteCode = caregiverInviteCode?.trim();
    const dbRoleCode = this.toDbRoleCode(normalizedRoleCode);

    const role = await this.prisma.role.findUnique({
      where: { roleCode: dbRoleCode },
    });

    if (!role) {
      throw new BadRequestException('Invalid role selected.');
    }

    if (normalizedRoleCode === 'caregiver' && !inviteCode) {
      throw new BadRequestException(
        'Invitation code is required for caregiver registration.',
      );
    }

    // Check if user exists by email
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email address already exists');
    }

    // If phone is provided, check if it's already in use
    if (phone) {
      const existingUserByPhone = await this.prisma.user.findUnique({
        where: { phone },
      });

      if (existingUserByPhone) {
        throw new ConflictException('User with this phone number already exists');
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    let registrationResult;
    try {
      registrationResult = await this.prisma.$transaction(async (tx) => {
        // When registering as caregiver, load and validate invitation inside transaction
        let invitation: {
          invitationId: bigint;
          elderUserId: bigint;
          inviterUserId: bigint;
          relationshipCode: string;
          status: string;
          expiresAt: Date;
        } | null = null;

        if (normalizedRoleCode === 'caregiver') {
          invitation = await tx.userInvitation.findUnique({
            where: { inviteCode: inviteCode! },
            select: {
              invitationId: true,
              elderUserId: true,
              inviterUserId: true,
              relationshipCode: true,
              status: true,
              expiresAt: true,
            },
          });

          if (!invitation) {
            throw new BadRequestException('Invalid caregiver invitation code.');
          }

          if (invitation.status !== 'pending') {
            throw new BadRequestException('Invitation has already been processed.');
          }

          if (invitation.expiresAt < new Date()) {
            throw new BadRequestException('Invitation has expired.');
          }
        }

        // Generate verification token
        const verificationToken = this.generateVerificationToken();
        const tokenExpiry = new Date();
        const expiryHours =
          parseInt(
            this.configService.get<string>('VERIFICATION_TOKEN_EXPIRY_HOURS') ||
            '24',
          ) || 24;
        tokenExpiry.setHours(tokenExpiry.getHours() + expiryHours);

        // Create user (email is required, phone is optional)
        const user = await tx.user.create({
          data: {
            email: email!,
            phone: phone || null,
            passwordHash: hashedPassword,
            full_name: name || '',
            emailVerified: false,
            verificationToken,
            verificationTokenExpiresAt: tokenExpiry,
          },
        });

        // Provision default FREE subscription
        await tx.subscription.create({
          data: {
            userId: user.userId,
            planId: null,
            status: 'active',
          },
        });

        // Attach selected role
        await tx.userRole.create({
          data: {
            userId: user.userId,
            roleId: role.roleId,
          },
        });

        if (normalizedRoleCode === 'caregiver' && invitation) {
          const now = new Date();

          // Check if assignment already exists (prevent duplicates)
          const existingAssignment = await tx.elderAssignment.findFirst({
            where: {
              elderUserId: invitation.elderUserId,
              caregiverUserId: user.userId,
            },
          });

          if (existingAssignment) {
            this.logger.warn(
              `Elder assignment already exists for caregiver ${user.userId} and elder ${invitation.elderUserId}`,
            );
          } else {
            // Validate relationshipCode is not empty
            if (!invitation.relationshipCode || invitation.relationshipCode.trim() === '') {
              throw new BadRequestException(
                'Invalid invitation: relationship code is missing.',
              );
            }

            // Normalize relationshipCode to lowercase to match lookup table
            // The lookup table stores codes in lowercase (e.g., "friend" not "Friend")
            const normalizedRelationshipCode = invitation.relationshipCode.trim().toLowerCase();

            await tx.elderAssignment.create({
              data: {
                elderUserId: invitation.elderUserId,
                caregiverUserId: user.userId,
                relationshipCode: normalizedRelationshipCode,
                relationshipDomain: 'relationships', // Explicitly set domain
                isPrimary: false,
              },
            });
          }

          await tx.userInvitation.update({
            where: { invitationId: invitation.invitationId },
            data: {
              status: 'accepted',
              acceptedUserId: user.userId,
              acceptedAt: now,
            },
          });
        }

        return { user, verificationToken };
      });
    } catch (error: any) {
      this.logger.error(
        `Registration transaction failed for ${email}: ${error.message}`,
        error.stack,
      );

      // Re-throw known exceptions
      if (
        error instanceof ConflictException ||
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }

      // Log detailed error information
      this.logger.error(
        `Registration error details: ${JSON.stringify({
          message: error.message,
          code: error.code,
          meta: error.meta,
        })}`,
      );

      // Provide more helpful error message
      if (error.code === 'P2002') {
        // Unique constraint violation
        const target = error.meta?.target || 'unknown field';
        throw new ConflictException(
          `A record with this ${target} already exists.`,
        );
      }

      throw new BadRequestException(
        `Registration failed: ${error.message || 'Unknown database error'}`,
      );
    }

    // Send verification email asynchronously (fire-and-forget)
    // This prevents registration from timing out if email service is slow
    this.logger.log(
      `Attempting to send verification email to ${registrationResult.user.email}`,
    );
    this.emailService
      .sendVerificationEmail(
        registrationResult.user.email!,
        registrationResult.verificationToken,
        registrationResult.user.full_name || undefined,
      )
      .then((success) => {
        if (!success) {
          this.logger.error(
            `Failed to send verification email to ${registrationResult.user.email}. Check email service logs for details.`,
          );
        } else {
          this.logger.log(
            `Verification email sent successfully to ${registrationResult.user.email}`,
          );
        }
      })
      .catch((error) => {
        this.logger.error(
          `Exception while sending verification email to ${registrationResult.user.email}: ${error.message}`,
          error.stack,
        );
      });

    return {
      message: 'Registration successful. Please verify your email.',
      userId: registrationResult.user.userId.toString(),
      role: this.toClientRoleCode(role.roleCode),
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.validateUser(loginDto.email, loginDto.password);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if email is verified (email is required)
    if (!user.emailVerified) {
      throw new UnauthorizedException(
        'Please verify your email address before logging in. Check your inbox for the verification email.',
      );
    }

    const activeRole = await this.resolveActiveRole(user.userId);
    const tokens = await this.generateTokens(user, activeRole);

    return {
      ...tokens,
      user: {
        id: user.userId.toString(),
        email: user.email,
        phone: user.phone,
        name: user.full_name,
        role: activeRole,
      },
    };
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user || !user.passwordHash) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      return null;
    }

    return user;
  }

  async validateGoogleUser(profile: {
    googleId: string;
    email: string;
    name: string;
  }): Promise<User> {
    // Note: googleId field doesn't exist in current schema, using email for lookup
    let user = await this.prisma.user.findUnique({
      where: { email: profile.email },
    });

    if (!user) {
      // Create new user for Google OAuth
      user = await this.prisma.user.create({
        data: {
          email: profile.email,
          full_name: profile.name,
          authProvider: 'google',
        },
      });

      // Create default FREE subscription
      await this.prisma.subscription.create({
        data: {
          userId: user.userId,
          planId: null,
          status: 'active',
        },
      });
    }

    // Ensure user has patient role
    const patientRole = await this.prisma.role.findUnique({
      where: { roleCode: this.toDbRoleCode('patient') },
    });

    if (patientRole) {
      const hasRole = await this.prisma.userRole.findFirst({
        where: { userId: user.userId, roleId: patientRole.roleId },
      });

      if (!hasRole) {
        await this.prisma.userRole.create({
          data: {
            userId: user.userId,
            roleId: patientRole.roleId,
          },
        });
      }
    }

    return user;
  }

  async verifyEmail(token: string) {
    const user = await this.prisma.user.findUnique({
      where: { verificationToken: token },
    });

    if (!user) {
      throw new NotFoundException('Invalid verification token');
    }

    if (user.verificationTokenExpiresAt && user.verificationTokenExpiresAt < new Date()) {
      throw new BadRequestException('Verification token has expired');
    }

    if (user.emailVerified) {
      throw new BadRequestException('Email has already been verified');
    }

    // Update user to mark email as verified and clear token
    await this.prisma.user.update({
      where: { userId: user.userId },
      data: {
        emailVerified: true,
        verificationToken: null,
        verificationTokenExpiresAt: null,
      },
    });

    return {
      message: 'Email verified successfully',
      userId: user.userId.toString(),
    };
  }

  async resendVerificationEmail(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      // Don't reveal if email exists or not for security
      return {
        message: 'If an account exists with this email, a verification email has been sent.',
      };
    }

    if (user.emailVerified) {
      throw new BadRequestException('Email has already been verified');
    }

    // Generate new verification token
    const verificationToken = this.generateVerificationToken();
    const tokenExpiry = new Date();
    const expiryHours =
      parseInt(
        this.configService.get<string>('VERIFICATION_TOKEN_EXPIRY_HOURS') ||
        '24',
      ) || 24;
    tokenExpiry.setHours(tokenExpiry.getHours() + expiryHours);

    // Update user with new token
    await this.prisma.user.update({
      where: { userId: user.userId },
      data: {
        verificationToken,
        verificationTokenExpiresAt: tokenExpiry,
      },
    });

    // Send verification email
    await this.emailService.resendVerificationEmail(
      user.email!,
      verificationToken,
      user.full_name || undefined,
    );

    return {
      message: 'Verification email sent successfully',
    };
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    const { email } = forgotPasswordDto;
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      // Don't reveal if email exists or not for security
      return {
        message: 'If an account exists with this email, a password reset link has been sent.',
      };
    }

    // Generate reset token
    const resetPasswordToken = this.generateVerificationToken();
    const tokenExpiry = new Date();
    // Reset tokens expire in 1 hour
    tokenExpiry.setHours(tokenExpiry.getHours() + 1);

    await this.prisma.user.update({
      where: { userId: user.userId },
      data: {
        resetPasswordToken,
        resetPasswordTokenExpiresAt: tokenExpiry,
      },
    });

    // Send reset email
    await this.emailService.sendPasswordResetEmail(
      user.email!,
      resetPasswordToken,
      user.full_name || undefined,
    );

    return {
      message: 'If an account exists with this email, a password reset link has been sent.',
    };
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto) {
    const { token, newPassword } = resetPasswordDto;

    const user = await this.prisma.user.findUnique({
      where: { resetPasswordToken: token },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    if (
      user.resetPasswordTokenExpiresAt &&
      user.resetPasswordTokenExpiresAt < new Date()
    ) {
      throw new BadRequestException('Reset token has expired');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update user password and clear reset token
    await this.prisma.user.update({
      where: { userId: user.userId },
      data: {
        passwordHash: hashedPassword,
        resetPasswordToken: null,
        resetPasswordTokenExpiresAt: null,
      },
    });

    return {
      message: 'Password reset successful. You can now login with your new password.',
    };
  }

  private generateVerificationToken(): string {
    return randomBytes(32).toString('hex');
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const user = await this.prisma.user.findUnique({
        where: { userId: BigInt(payload.sub) },
      });

      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const activeRole = await this.resolveActiveRole(user.userId);
      return this.generateTokens(user, activeRole);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private async generateTokens(user: User, role?: string) {
    const roleCode = role || (await this.resolveActiveRole(user.userId));
    const payload = {
      sub: user.userId.toString(),
      email: user.email || '',
      role: roleCode,
    };

    const jwtSecret =
      this.configService.get<string>('JWT_SECRET') || 'default-secret';
    const jwtExpiration =
      this.configService.get<string>('JWT_EXPIRATION') || '7d';
    const jwtRefreshSecret =
      this.configService.get<string>('JWT_REFRESH_SECRET') ||
      'default-refresh-secret';
    const jwtRefreshExpiration =
      this.configService.get<string>('JWT_REFRESH_EXPIRATION') || '30d';

    const accessToken = this.jwtService.sign(payload, {
      secret: jwtSecret,
      expiresIn: jwtExpiration as any,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: jwtRefreshSecret,
      expiresIn: jwtRefreshExpiration as any,
    });

    return {
      accessToken,
      refreshToken,
    };
  }
  private async resolveActiveRole(userId: bigint): Promise<string> {
    const role = await this.prisma.userRole.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        role: true,
      },
    });

    const roleCode = role?.role.roleCode;
    return this.toClientRoleCode(roleCode);
  }

  private toDbRoleCode(roleCode: string | undefined): string {
    const normalized = (roleCode || '').trim().toLowerCase();
    return normalized || 'patient';
  }

  private toClientRoleCode(roleCode: string | undefined): string {
    if (!roleCode) {
      return 'patient';
    }
    return roleCode.toLowerCase();
  }
}
