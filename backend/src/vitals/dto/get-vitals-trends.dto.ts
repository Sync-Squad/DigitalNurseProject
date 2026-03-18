import { IsOptional, IsNumber, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export class GetVitalsTrendsDto extends BaseQueryDto {
  @ApiPropertyOptional({ description: 'Kind code of the vital (e.g., blood_pressure)' })
  @IsOptional()
  @IsString()
  kindCode?: string;

  @ApiPropertyOptional({ description: 'Period: weekly or monthly' })
  @IsOptional()
  @IsString()
  period?: string;

  @ApiPropertyOptional({ example: 7, description: 'Number of days for trends' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  days?: number;
}
