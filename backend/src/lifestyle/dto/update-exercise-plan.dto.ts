import { PartialType } from '@nestjs/swagger';
import { CreateExercisePlanDto } from './create-exercise-plan.dto';

export class UpdateExercisePlanDto extends PartialType(CreateExercisePlanDto) {}

