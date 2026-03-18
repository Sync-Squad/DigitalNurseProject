import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export class GetLifestyleDto extends BaseQueryDto {
  @ApiPropertyOptional({ description: 'Filter by specific date (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  date?: string;

  @ApiPropertyOptional({ description: 'Filter from start date (YYYY-MM-DD)' })
  @IsOptional()
  @IsString()
  startDate?: string;
}
