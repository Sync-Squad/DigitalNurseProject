import { ApiProperty } from '@nestjs/swagger';

export class PlanComplianceDetailDto {
  @ApiProperty()
  planned!: {
    mealType?: string;
    activityType?: string;
    description: string;
    calories?: number;
    caloriesBurned?: number;
    durationMinutes?: number;
  };

  @ApiProperty()
  actual!: {
    mealType?: string;
    activityType?: string;
    description: string;
    calories?: number;
    caloriesBurned?: number;
    durationMinutes?: number;
  } | null;

  @ApiProperty()
  matched!: boolean;
}

export class DailyComplianceDto {
  @ApiProperty()
  date!: string;

  @ApiProperty()
  planned!: number;

  @ApiProperty()
  actual!: number;

  @ApiProperty()
  matched!: number;

  @ApiProperty()
  compliance!: number;

  @ApiProperty({ type: [PlanComplianceDetailDto] })
  details!: PlanComplianceDetailDto[];
}

export class PlanComplianceResponseDto {
  @ApiProperty()
  planId!: string;

  @ApiProperty()
  period!: {
    startDate: string;
    endDate: string;
  };

  @ApiProperty()
  overallCompliance!: number;

  @ApiProperty({ type: [DailyComplianceDto] })
  dailyBreakdown!: DailyComplianceDto[];
}

