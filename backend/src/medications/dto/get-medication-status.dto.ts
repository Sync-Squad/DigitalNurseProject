import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export class GetMedicationStatusDto extends BaseQueryDto {
  @ApiPropertyOptional({ description: 'Filter by specific date (YYYY-MM-DD)', type: String })
  @IsOptional()
  @IsString()
  date?: string;
}
