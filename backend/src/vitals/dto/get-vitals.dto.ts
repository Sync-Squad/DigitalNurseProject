import { IsOptional, IsEnum, IsString, IsInt, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
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

export class GetRecentVitalsDto extends BaseQueryDto {
  @ApiPropertyOptional({ description: 'Number of records to return', type: Number, default: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  limit?: number = 10;

  @ApiPropertyOptional({ enum: VitalType, description: 'Optional type filter' })
  @IsOptional()
  @IsEnum(VitalType)
  type?: VitalType;
}

