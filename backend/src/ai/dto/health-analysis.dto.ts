import { IsOptional, IsNumber, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class HealthAnalysisDto {
  @ApiPropertyOptional({
    description: 'Elder user ID to analyze',
  })
  @IsOptional()
  @IsNumber()
  elderUserId?: bigint;

  @ApiPropertyOptional({
    description: 'Start date for analysis period',
    example: '2024-01-01',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'End date for analysis period',
    example: '2024-12-31',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    description: 'Analysis types to include',
    example: ['medication_adherence', 'health_trends'],
    isArray: true,
  })
  @IsOptional()
  analysisTypes?: string[];
}

