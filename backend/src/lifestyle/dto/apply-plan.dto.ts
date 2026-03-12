import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ApplyPlanDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required for caregivers)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ example: '2024-01-15', description: 'Start date for applying the plan (week starts from this date)' })
  @IsDateString()
  @IsNotEmpty()
  startDate!: string;

  @ApiPropertyOptional({
    example: false,
    description: 'Whether to overwrite existing logs for the week',
    default: false,
  })
  @IsBoolean()
  @IsOptional()
  overwriteExisting?: boolean;
}

