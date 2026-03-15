import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { verificationEmailTemplate } from './templates/verification-email.template';
import { caregiverInvitationEmailTemplate } from './templates/caregiver-invitation-email.template';
import { forgotPasswordEmailTemplate } from './templates/forgot-password-email.template';
import { caregiverStatusEmailTemplate } from './templates/caregiver-status-email.template';
import { caregiverContactEmailTemplate } from './templates/caregiver-contact.template';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private readonly fromEmail: string;
  private readonly appName: string;
  private readonly appBaseUrl: string;

  constructor(private configService: ConfigService) {
    const smtpHost = this.configService.get<string>('SMTP_HOST')?.trim();
    const smtpPort = this.configService.get<string>('SMTP_PORT')?.trim();
    const smtpSecure = this.configService.get<string>('SMTP_SECURE')?.trim();
    const smtpUser = this.configService.get<string>('SMTP_USER')?.trim();
    const smtpPass = this.configService.get<string>('SMTP_PASS')?.trim();

    if (!smtpHost || !smtpPort || !smtpUser || !smtpPass) {
      this.logger.warn(
        'SMTP configuration not found. Email service will not work.',
      );
      this.logger.warn(
        `Missing: ${!smtpHost ? 'SMTP_HOST ' : ''}${!smtpPort ? 'SMTP_PORT ' : ''}${!smtpUser ? 'SMTP_USER ' : ''}${!smtpPass ? 'SMTP_PASS' : ''}`,
      );
    } else {
      const port = Number(smtpPort);
      const secure = smtpSecure === 'true' || smtpSecure === '1';

      this.logger.log(
        `Initializing SMTP transporter: ${smtpHost}:${port} (secure: ${secure}, user: ${smtpUser})`,
      );
      this.logger.debug(
        `SMTP config - Host length: ${smtpHost?.length}, Port: ${port}, Secure: ${secure}, User length: ${smtpUser?.length}, Pass length: ${smtpPass?.length}`,
      );

      // Configure transporter - matching the working example format
      // For port 465, secure MUST be true
      this.transporter = nodemailer.createTransport({
        host: smtpHost,
        port: port,
        secure: secure, // MUST be true for 465
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      // Verify transporter configuration (async, non-blocking)
      this.transporter.verify((error: Error | null, success?: boolean) => {
        if (error) {
          this.logger.error(
            `SMTP transporter verification failed: ${error.message}`,
          );
          if ('code' in error) {
            this.logger.error(`Error code: ${(error as any).code}`);
          }
          if ('command' in error) {
            this.logger.error(`Failed command: ${(error as any).command}`);
          }
          this.logger.error(
            'Please check your SMTP credentials (SMTP_USER, SMTP_PASS) and ensure:',
          );
          this.logger.error(
            '1. The email account allows SMTP access',
          );
          this.logger.error(
            '2. If 2FA is enabled, use an app-specific password',
          );
          this.logger.error(
            '3. The account is not locked or restricted',
          );
          this.logger.error(
            '4. For PrivateEmail, try port 587 with SMTP_SECURE=false if port 465 fails',
          );
        } else {
          this.logger.log('SMTP transporter verified successfully');
        }
      });
    }
    this.fromEmail =
      this.configService.get<string>('MAIL_FROM') ||
      'Sync Squad <hcn@sync-squad.com>';
    this.appName = this.configService.get<string>('APP_NAME') || 'Digital Nurse';
    this.appBaseUrl =
      this.configService.get<string>('APP_BASE_URL') ||
      //this.configService.get<string>('FRONTEND_URL') || 'http://100.42.177.77:3000';
      this.configService.get<string>('FRONTEND_URL') || 'http://109.199.126.203:3000';

  }

  async sendVerificationEmail(
    email: string,
    token: string,
    name?: string,
  ): Promise<boolean> {
    try {
      if (!this.transporter) {
        this.logger.error('Nodemailer transporter not initialized. Cannot send email.');
        return false;
      }

      const verificationUrl = `${this.appBaseUrl}/email-verification?token=${token}`;
      const html = verificationEmailTemplate({
        name: name || 'User',
        verificationUrl,
        appName: this.appName,
      });

      await this.transporter.sendMail({
        from: this.fromEmail,
        to: email,
        subject: `Verify your ${this.appName} account`,
        html,
      });

      this.logger.log(`Verification email sent to ${email}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Error sending verification email: ${errorMessage}`);
      return false;
    }
  }

  async sendCaregiverInvitationEmail(
    email: string,
    inviteCode: string,
    patientName: string,
    relationship?: string,
  ): Promise<boolean> {
    try {
      if (!this.transporter) {
        this.logger.error('Nodemailer transporter not initialized. Cannot send email.');
        return false;
      }

      const registrationUrl = `${this.appBaseUrl}/register?inviteCode=${inviteCode}`;
      const html = caregiverInvitationEmailTemplate({
        inviteCode,
        patientName,
        relationship: relationship || 'loved one',
        registrationUrl,
        appName: this.appName,
      });

      await this.transporter.sendMail({
        from: this.fromEmail,
        to: email,
        subject: `You've been invited to be a caregiver on ${this.appName}`,
        html,
      });

      this.logger.log(`Caregiver invitation email sent to ${email}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Error sending caregiver invitation email: ${errorMessage}`,
      );
      return false;
    }
  }

  async resendVerificationEmail(
    email: string,
    token: string,
    name?: string,
  ): Promise<boolean> {
    return this.sendVerificationEmail(email, token, name);
  }

  async sendPasswordResetEmail(
    email: string,
    code: string,
    name?: string,
  ): Promise<boolean> {
    try {
      if (!this.transporter) {
        this.logger.error('Nodemailer transporter not initialized. Cannot send email.');
        return false;
      }

      const html = forgotPasswordEmailTemplate({
        name: name || 'User',
        code,
        appName: this.appName,
      });

      await this.transporter.sendMail({
        from: this.fromEmail,
        to: email,
        subject: `Password Reset Code for ${this.appName}`,
        html,
      });

      this.logger.log(`Password reset code email sent to ${email}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Error sending password reset email: ${errorMessage}`);
      return false;
    }
  }

  async sendCaregiverStatusUpdateEmail(
    email: string,
    patientName: string,
    status: 'enabled' | 'disabled',
  ): Promise<boolean> {
    try {
      if (!this.transporter) {
        this.logger.error('Nodemailer transporter not initialized. Cannot send email.');
        return false;
      }

      const html = caregiverStatusEmailTemplate({
        patientName,
        status,
        appName: this.appName,
      });

      const subject = status === 'enabled'
        ? `Caregiver Access Restored for ${patientName}`
        : `Caregiver Access Revoked for ${patientName}`;

      await this.transporter.sendMail({
        from: this.fromEmail,
        to: email,
        subject,
        html,
      });

      this.logger.log(`Caregiver status update email (${status}) sent to ${email}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Error sending status update email: ${errorMessage}`);
      return false;
    }
  }

  async sendCaregiverContactEmail(
    email: string,
    patientName: string,
    message: string,
    subject?: string,
  ): Promise<boolean> {
    try {
      if (!this.transporter) {
        this.logger.error('Nodemailer transporter not initialized. Cannot send email.');
        return false;
      }

      const html = caregiverContactEmailTemplate({
        patientName,
        message,
        appName: this.appName,
      });

      await this.transporter.sendMail({
        from: this.fromEmail,
        to: email,
        subject: subject || `Message from ${patientName} via ${this.appName}`,
        html,
      });

      this.logger.log(`Caregiver contact email sent to ${email} from ${patientName}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error(`Error sending caregiver contact email: ${errorMessage}`);
      return false;
    }
  }
}

