import { IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ToggleStatusDto {
  @IsBoolean()
  @ApiProperty({ description: 'Whether the caregiver access is active' })
  isActive!: boolean;
}
