import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class BaseQueryDto {
  @ApiPropertyOptional({ 
    example: '1', 
    description: 'Target elder user ID (required when caregiver)' 
  })
  @IsOptional()
  @IsString()
  elderUserId?: string;
}
