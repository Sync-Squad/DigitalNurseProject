import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsInt,
  IsDateString,
  IsEnum,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum ActivityType {
  WALKING = 'walking',
  RUNNING = 'running',
  CYCLING = 'cycling',
  SWIMMING = 'swimming',
  YOGA = 'yoga',
  GYM = 'gym',
  SPORTS = 'sports',
  OTHER = 'other',
}

export enum Intensity {
  LOW = 'low',
  MODERATE = 'moderate',
  HIGH = 'high',
}

export class CreateExerciseLogDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required for caregivers)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ enum: ActivityType, example: ActivityType.WALKING })
  @IsEnum(ActivityType)
  activityType!: ActivityType;

  @ApiProperty({ example: 'Morning walk in the park', description: 'Exercise description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: 30, description: 'Duration in minutes' })
  @IsInt()
  @Min(0)
  durationMinutes!: number;

  @ApiProperty({ example: 150, description: 'Calories burned' })
  @IsInt()
  @Min(0)
  caloriesBurned!: number;

  @ApiProperty({ example: '2024-01-15', description: 'Date of the exercise' })
  @IsDateString()
  logDate!: string;

  @ApiPropertyOptional({ enum: Intensity, example: Intensity.MODERATE })
  @IsEnum(Intensity)
  @IsOptional()
  intensity?: Intensity;

  @ApiPropertyOptional({ example: 'Felt great' })
  @IsString()
  @IsOptional()
  notes?: string;
}

