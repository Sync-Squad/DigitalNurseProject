import { IsString, IsNotEmpty, IsOptional, IsInt, IsDateString, IsEnum, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum MealType {
  BREAKFAST = 'breakfast',
  LUNCH = 'lunch',
  DINNER = 'dinner',
  SNACK = 'snack',
}

export class CreateDietLogDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required for caregivers)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ enum: MealType, example: MealType.BREAKFAST })
  @IsEnum(MealType)
  mealType!: MealType;

  @ApiProperty({ example: 'Oatmeal with berries', description: 'Food items/description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: 350, description: 'Calories' })
  @IsInt()
  @Min(0)
  calories!: number;

  @ApiProperty({ example: '2024-01-15', description: 'Date of the meal' })
  @IsDateString()
  logDate!: string;

  @ApiPropertyOptional({ example: 'Added honey' })
  @IsString()
  @IsOptional()
  notes?: string;
}

