import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export class GetPlanComplianceDto extends BaseQueryDto {
  @ApiPropertyOptional({ description: 'Filter from start date (YYYY-MM-DD)', type: String })
  @IsOptional()
  @IsString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter to end date (YYYY-MM-DD)', type: String })
  @IsOptional()
  @IsString()
  endDate?: string;
}
