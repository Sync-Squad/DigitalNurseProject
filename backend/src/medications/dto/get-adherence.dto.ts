import { IsOptional, IsNumber, IsEnum, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export enum AdherencePeriod {
  WEEKLY = 'weekly',
  MONTHLY = 'monthly',
}

export class GetAdherenceDto extends BaseQueryDto {
  @ApiPropertyOptional({ 
    enum: AdherencePeriod, 
    example: AdherencePeriod.WEEKLY,
    description: 'Period for adherence calculation'
  })
  @IsOptional()
  @IsEnum(AdherencePeriod)
  period?: AdherencePeriod;

  @ApiPropertyOptional({ 
    example: 7, 
    description: 'Number of days to calculate adherence for' 
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  days?: number;
}
