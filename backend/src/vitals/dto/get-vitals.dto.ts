import { IsOptional, IsEnum, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';
import { VitalType } from './create-vital.dto';

export class GetVitalsDto extends BaseQueryDto {
  @ApiPropertyOptional({ enum: VitalType, description: 'Type of vital measurement' })
  @IsOptional()
  @IsEnum(VitalType)
  type?: VitalType;

  @ApiPropertyOptional({ description: 'Filter from start date', type: String })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter to end date', type: String })
  @IsOptional()
  @IsString()
  endDate?: string;
}
