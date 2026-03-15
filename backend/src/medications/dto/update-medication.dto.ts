import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  MedicineForm,
  MedicineFrequency,
  ReminderTimeDto,
  MedicinePriority,
} from './create-medication.dto';
import {
  IsArray,
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateMedicationDto {
  @ApiPropertyOptional({ description: 'Medicine name' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ description: 'Dosage instructions' })
  @IsString()
  @IsOptional()
  dosage?: string;

  @ApiPropertyOptional({ description: 'Additional notes' })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ enum: MedicineForm })
  @IsEnum(MedicineForm)
  @IsOptional()
  medicineForm?: MedicineForm;

  @ApiPropertyOptional({ description: 'Strength label, e.g., 75mg' })
  @IsString()
  @IsOptional()
  strength?: string;

  @ApiPropertyOptional({ description: 'Dose amount text, e.g., 1 tablet' })
  @IsString()
  @IsOptional()
  doseAmount?: string;

  @ApiPropertyOptional({
    type: [ReminderTimeDto],
    description: 'Updated reminder times',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReminderTimeDto)
  @IsOptional()
  reminderTimes?: ReminderTimeDto[];

  @ApiPropertyOptional({ enum: MedicineFrequency })
  @IsEnum(MedicineFrequency)
  @IsOptional()
  frequency?: MedicineFrequency;

  @ApiPropertyOptional({
    type: [Number],
    description: 'Updated periodic days mask (1=Monday, 7=Sunday)',
  })
  @IsArray()
  @IsOptional()
  periodicDays?: number[];

  @ApiPropertyOptional({ description: 'Updated start date in ISO format' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Updated end date in ISO format' })
  @IsDateString()
  @IsOptional()
  endDate?: string;

  @ApiPropertyOptional({
    description: 'Target elder user ID (must remain consistent)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;
  @ApiPropertyOptional({ enum: MedicinePriority })
  @IsEnum(MedicinePriority)
  @IsOptional()
  priority?: MedicinePriority;
}

