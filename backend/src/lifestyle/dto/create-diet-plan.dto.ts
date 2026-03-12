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
import { MealType } from './create-diet-log.dto';

export class DietPlanItemDto {
  @ApiProperty({ example: 0, description: 'Day of week (0=Sunday, 6=Saturday)' })
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  @ApiProperty({ enum: MealType, example: MealType.BREAKFAST })
  @IsEnum(MealType)
  mealType!: MealType;

  @ApiProperty({ example: 'Oatmeal with berries', description: 'Food items/description' })
  @IsString()
  @IsNotEmpty()
  description!: string;

  @ApiPropertyOptional({ example: 350, description: 'Calories' })
  @IsInt()
  @Min(0)
  @IsOptional()
  calories?: number;

  @ApiPropertyOptional({ example: 'Added honey' })
  @IsString()
  @IsOptional()
  notes?: string;
}

export class CreateDietPlanDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required for caregivers)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ example: 'Weekly Weight Loss Plan', description: 'Plan name' })
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  planName!: string;

  @ApiPropertyOptional({ example: 'A balanced diet plan for weight loss', description: 'Plan description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({
    type: [DietPlanItemDto],
    description: 'Array of meal items for the week',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DietPlanItemDto)
  items!: DietPlanItemDto[];
}

