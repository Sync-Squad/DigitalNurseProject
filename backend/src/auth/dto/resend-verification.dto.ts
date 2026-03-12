import { IsEmail } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResendVerificationDto {
  @ApiProperty({ example: 'user@example.com', description: 'Email address to resend verification to' })
  @IsEmail()
  email!: string;
}

