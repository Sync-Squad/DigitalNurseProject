import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ContactCaregiverDto {
  @ApiProperty({
    example: 'Hello, I need some help with my medications.',
    description: 'The message to send to the caregiver',
  })
  @IsString()
  @IsNotEmpty()
  message!: string;

  @ApiProperty({
    example: 'Medication assistance needed',
    description: 'Optional subject for the email',
    required: false,
  })
  @IsString()
  @IsOptional()
  subject?: string;
}
