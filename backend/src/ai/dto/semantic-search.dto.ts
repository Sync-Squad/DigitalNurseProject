import { IsString, IsOptional, IsNumber, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SemanticSearchDto {
  @ApiProperty({
    description: 'Natural language search query',
    example: 'Find notes about dizziness',
  })
  @IsString()
  query!: string;

  @ApiPropertyOptional({
    description: 'Filter by table/entity type',
    example: 'caregiver_notes',
    enum: [
      'caregiver_notes',
      'medications',
      'vital_measurements',
      'diet_logs',
      'exercise_logs',
      'med_intakes',
      'user_documents',
    ],
  })
  @IsOptional()
  @IsString()
  entityType?: string;

  @ApiPropertyOptional({
    description: 'Minimum similarity threshold (0-1)',
    default: 0.7,
    minimum: 0,
    maximum: 1,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  threshold?: number;

  @ApiPropertyOptional({
    description: 'Maximum number of results',
    default: 10,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number;

  @ApiPropertyOptional({
    description: 'User ID to filter results (for access control)',
  })
  @IsOptional()
  @IsNumber()
  userId?: bigint;

  @ApiPropertyOptional({
    description: 'Elder user ID to filter results',
  })
  @IsOptional()
  @IsNumber()
  elderUserId?: bigint;
}

