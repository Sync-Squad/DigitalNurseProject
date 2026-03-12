import { IsString, IsNotEmpty, IsOptional, IsEnum, IsEmail } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateInvitationDto {
  @ApiPropertyOptional({ example: '+1234567890', description: 'Phone number of caregiver to invite' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: 'caregiver@example.com', description: 'Email address of caregiver to invite' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: 'John Doe', description: 'Name of caregiver (optional)' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: 'son', description: 'Relationship code' })
  @IsString()
  @IsNotEmpty()
  relationship!: string;

  @ApiPropertyOptional({
    example: '1',
    description: 'Elder user ID (defaults to current user)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;
}

