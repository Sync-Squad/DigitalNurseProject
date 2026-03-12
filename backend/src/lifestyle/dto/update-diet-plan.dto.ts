import { PartialType } from '@nestjs/swagger';
import { CreateDietPlanDto } from './create-diet-plan.dto';

export class UpdateDietPlanDto extends PartialType(CreateDietPlanDto) {}

