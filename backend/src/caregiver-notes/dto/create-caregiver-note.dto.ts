import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCaregiverNoteDto {
  @ApiPropertyOptional({
    example: '1',
    description: 'Elder user ID (required when caregiver)',
  })
  @IsString()
  @IsOptional()
  elderUserId?: string;

  @ApiProperty({
    example: 'Patient seems to be doing well today. Appetite is good.',
    description: 'Note text content',
  })
  @IsString()
  @IsNotEmpty()
  noteText!: string;
}

