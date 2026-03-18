import { IsOptional, IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BaseQueryDto } from '../../common/dto/base-query.dto';

export class GetDailySummaryDto extends BaseQueryDto {
  @ApiProperty({ description: 'Specific date for the summary (YYYY-MM-DD)', type: String })
  @IsNotEmpty()
  @IsString()
  date!: string;
}
