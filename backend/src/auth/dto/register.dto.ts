import { IsEmail, IsString, MinLength, IsOptional, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'user@example.com', description: 'Email address (required)' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'StrongPassword123!' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ example: 'John Doe', required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: '+923001234567',
    description: 'Phone number with country code (e.g., +92 for Pakistan) - optional',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\+92\d{10}$/, { message: 'Phone number must be in format +92XXXXXXXXXX (Pakistan format)' })
  phone?: string;

  @ApiPropertyOptional({
    example: 'caregiver',
    description: 'Desired role code (`patient` if omitted)',
  })
  @IsOptional()
  @IsString()
  roleCode?: string;

  @ApiPropertyOptional({
    example: 'cg-XYZ123',
    description: 'Invitation code required when registering as a caregiver',
  })
  @IsOptional()
  @IsString()
  caregiverInviteCode?: string;
}
