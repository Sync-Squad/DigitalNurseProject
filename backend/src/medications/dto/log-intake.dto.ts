import { IsEnum, IsDateString, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum IntakeStatus {
  PENDING = 'pending',
  TAKEN = 'taken',
  MISSED = 'missed',
  SKIPPED = 'skipped',
  SNOOZED = 'snoozed',
}

export class LogIntakeDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required when caregiver)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ enum: IntakeStatus, example: IntakeStatus.TAKEN })
  @IsEnum(IntakeStatus)
  status!: IntakeStatus;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Scheduled time' })
  @IsDateString()
  scheduledTime!: string;

  @ApiPropertyOptional({ example: '2024-01-15T08:15:00Z', description: 'Actual taken time' })
  @IsDateString()
  @IsOptional()
  takenTime?: string;

  @ApiPropertyOptional({ example: 'Forgot to take earlier' })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ example: 'forgot', description: 'Reason code for skipping or missing' })
  @IsString()
  @IsOptional()
  skipReasonCode?: string;
}

