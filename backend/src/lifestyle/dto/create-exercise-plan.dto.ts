import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsInt,
  IsEnum,
  IsArray,
  ValidateNested,
  Min,
  MinLength,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ActivityType, Intensity } from './create-exercise-log.dto';

export class ExercisePlanItemDto {
  @ApiProperty({ example: 0, description: 'Day of week (0=Sunday, 6=Saturday)' })
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  @ApiProperty({ enum: ActivityType, example: ActivityType.WALKING })
  @IsEnum(ActivityType)
  activityType!: ActivityType;

  @ApiProperty({ example: 'Morning walk in the park', description: 'Exercise description' })
  @IsString()
  @IsNotEmpty()
  description!: string;

  @ApiPropertyOptional({ example: 30, description: 'Duration in minutes' })
  @IsInt()
  @Min(0)
  @IsOptional()
  durationMinutes?: number;

  @ApiPropertyOptional({ example: 150, description: 'Calories burned' })
  @IsInt()
  @Min(0)
  @IsOptional()
  caloriesBurned?: number;

  @ApiPropertyOptional({ enum: Intensity, example: Intensity.MODERATE })
  @IsEnum(Intensity)
  @IsOptional()
  intensity?: Intensity;

  @ApiPropertyOptional({ example: 'Felt great' })
  @IsString()
  @IsOptional()
  notes?: string;
}

export class CreateExercisePlanDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required for caregivers)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ example: 'Weekly Fitness Plan', description: 'Plan name' })
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  planName!: string;

  @ApiPropertyOptional({ example: 'A balanced workout plan for fitness', description: 'Plan description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({
    type: [ExercisePlanItemDto],
    description: 'Array of workout items for the week',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ExercisePlanItemDto)
  items!: ExercisePlanItemDto[];
}

