import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  IsDateString,
  IsEnum,
  ValidateNested,
  IsNumber,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum MedicineFrequency {
  DAILY = 'daily',
  TWICE_DAILY = 'twiceDaily',
  THRICE_DAILY = 'thriceDaily',
  WEEKLY = 'weekly',
  AS_NEEDED = 'asNeeded',
  PERIODIC = 'periodic',
  BEFORE_MEAL = 'beforeMeal',
  AFTER_MEAL = 'afterMeal',
}

export enum MedicineForm {
  TABLET = 'tablet',
  CAPSULE = 'capsule',
  SYRUP = 'syrup',
  INJECTION = 'injection',
  DROPS = 'drops',
  INHALER = 'inhaler',
  OTHER = 'other',
}

export class ReminderTimeDto {
  @ApiProperty({ example: '08:00', description: 'Time in HH:mm format' })
  @IsString()
  @IsNotEmpty()
  time!: string;
}

export enum MedicinePriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
}

export class CreateMedicationDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Target elder user ID (required when caregiver)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({ example: 'Aspirin', description: 'Medicine name' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: '1 tablet of 75mg', description: 'Dosage description' })
  @IsString()
  @IsNotEmpty()
  dosage!: string;

  @ApiProperty({ enum: MedicineFrequency, example: MedicineFrequency.DAILY })
  @IsEnum(MedicineFrequency)
  frequency!: MedicineFrequency;

  @ApiProperty({ example: '2024-01-01', description: 'Start date' })
  @IsDateString()
  startDate!: string;

  @ApiPropertyOptional({ example: '2024-12-31', description: 'End date (optional)' })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiProperty({
    type: [ReminderTimeDto],
    example: [{ time: '08:00' }, { time: '20:00' }],
    description: 'Reminder times',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReminderTimeDto)
  reminderTimes!: ReminderTimeDto[];

  @ApiPropertyOptional({ example: 'Take with food' })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ enum: MedicineForm })
  @IsEnum(MedicineForm)
  @IsOptional()
  medicineForm?: MedicineForm;

  @ApiPropertyOptional({ example: '75mg', description: 'Medicine strength' })
  @IsString()
  @IsOptional()
  strength?: string;

  @ApiPropertyOptional({ example: '1 tablet', description: 'Dose amount' })
  @IsString()
  @IsOptional()
  doseAmount?: string;

  @ApiPropertyOptional({
    type: [Number],
    example: [1, 3, 5],
    description: 'Days of week (1=Monday, 7=Sunday) for periodic frequency',
  })
  @IsArray()
  @IsNumber({}, { each: true })
  @IsOptional()
  periodicDays?: number[];

  @ApiPropertyOptional({ enum: MedicinePriority, default: MedicinePriority.MEDIUM })
  @IsEnum(MedicinePriority)
  @IsOptional()
  priority?: MedicinePriority;
}

