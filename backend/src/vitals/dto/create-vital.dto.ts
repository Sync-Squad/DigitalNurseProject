import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
  IsEnum,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum VitalType {
  BLOOD_PRESSURE = 'bloodPressure',
  BLOOD_SUGAR = 'bloodSugar',
  HEART_RATE = 'heartRate',
  TEMPERATURE = 'temperature',
  OXYGEN_SATURATION = 'oxygenSaturation',
  WEIGHT = 'weight',
}

export class CreateVitalDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required when caregiver)',
  })
  @Transform(({ value }) => value != null ? String(value) : undefined)
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ enum: VitalType, example: VitalType.BLOOD_PRESSURE })
  @IsEnum(VitalType)
  type!: VitalType;

  @ApiProperty({
    example: '120/80',
    description: 'Value as string. For blood pressure use "systolic/diastolic" format',
  })
  @Transform(({ value }) => String(value))
  @IsString()
  @IsNotEmpty()
  value!: string;

  @ApiProperty({ example: '2024-01-15T08:00:00Z', description: 'Timestamp' })
  @IsDateString()
  timestamp!: string;

  @ApiPropertyOptional({ example: 'Morning reading' })
  @IsString()
  @IsOptional()
  notes?: string;
}

