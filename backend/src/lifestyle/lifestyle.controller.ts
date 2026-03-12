import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  UseGuards,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { LifestyleService } from './lifestyle.service';
import { CreateDietLogDto } from './dto/create-diet-log.dto';
import { CreateExerciseLogDto } from './dto/create-exercise-log.dto';
import { CreateDietPlanDto } from './dto/create-diet-plan.dto';
import { UpdateDietPlanDto } from './dto/update-diet-plan.dto';
import { CreateExercisePlanDto } from './dto/create-exercise-plan.dto';
import { UpdateExercisePlanDto } from './dto/update-exercise-plan.dto';
import { ApplyPlanDto } from './dto/apply-plan.dto';
import { PlanComplianceResponseDto } from './dto/plan-compliance.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessControlService } from '../common/services/access-control.service';

@ApiTags('Lifestyle')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('lifestyle')
export class LifestyleController {
  constructor(
    private readonly lifestyleService: LifestyleService,
    private readonly accessControlService: AccessControlService,
  ) {}

  private async resolveContext(user: any, elderUserId?: string) {
    return this.accessControlService.resolveActorContext(user, elderUserId);
  }

  @Post('diet')
  @ApiOperation({ summary: 'Add a diet log entry' })
  @ApiResponse({ status: 201, description: 'Diet log created successfully' })
  async createDietLog(@CurrentUser() user: any, @Body() createDto: CreateDietLogDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.lifestyleService.createDietLog(context, createDto);
  }

  @Get('diet')
  @ApiOperation({ summary: 'Get all diet logs' })
  @ApiQuery({ name: 'date', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of diet logs' })
  async findAllDietLogs(
    @CurrentUser() user: any,
    @Query('date') date?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findAllDietLogs(context, date);
  }

  @Delete('diet/:id')
  @ApiOperation({ summary: 'Delete a diet log' })
  @ApiResponse({ status: 200, description: 'Diet log deleted successfully' })
  async removeDietLog(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.removeDietLog(context, BigInt(id));
  }

  @Post('exercise')
  @ApiOperation({ summary: 'Add an exercise log entry' })
  @ApiResponse({ status: 201, description: 'Exercise log created successfully' })
  async createExerciseLog(
    @CurrentUser() user: any,
    @Body() createDto: CreateExerciseLogDto,
  ) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.lifestyleService.createExerciseLog(context, createDto);
  }

  @Get('exercise')
  @ApiOperation({ summary: 'Get all exercise logs' })
  @ApiQuery({ name: 'date', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of exercise logs' })
  async findAllExerciseLogs(
    @CurrentUser() user: any,
    @Query('date') date?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findAllExerciseLogs(context, date);
  }

  @Delete('exercise/:id')
  @ApiOperation({ summary: 'Delete an exercise log' })
  @ApiResponse({ status: 200, description: 'Exercise log deleted successfully' })
  async removeExerciseLog(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.removeExerciseLog(context, BigInt(id));
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get daily summary' })
  @ApiQuery({ name: 'date', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Daily summary' })
  async getDailySummary(
    @CurrentUser() user: any,
    @Query('date') date: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.getDailySummary(context, date);
  }

  @Get('summary/weekly')
  @ApiOperation({ summary: 'Get weekly summary' })
  @ApiResponse({ status: 200, description: 'Weekly summary' })
  async getWeeklySummary(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.getWeeklySummary(context);
  }

  // ============================================
  // Diet Plan Endpoints
  // ============================================

  @Post('diet-plans')
  @ApiOperation({ summary: 'Create a diet plan' })
  @ApiResponse({ status: 201, description: 'Diet plan created successfully' })
  async createDietPlan(@CurrentUser() user: any, @Body() createDto: CreateDietPlanDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.lifestyleService.createDietPlan(context, createDto);
  }

  @Get('diet-plans')
  @ApiOperation({ summary: 'Get all diet plans' })
  @ApiResponse({ status: 200, description: 'List of diet plans' })
  async findAllDietPlans(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findAllDietPlans(context);
  }

  @Get('diet-plans/:id')
  @ApiOperation({ summary: 'Get a diet plan by ID' })
  @ApiResponse({ status: 200, description: 'Diet plan details' })
  async findDietPlanById(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findDietPlanById(context, BigInt(id));
  }

  @Put('diet-plans/:id')
  @ApiOperation({ summary: 'Update a diet plan' })
  @ApiResponse({ status: 200, description: 'Diet plan updated successfully' })
  async updateDietPlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() updateDto: UpdateDietPlanDto,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId || updateDto.elderUserId);
    return this.lifestyleService.updateDietPlan(context, BigInt(id), updateDto);
  }

  @Delete('diet-plans/:id')
  @ApiOperation({ summary: 'Delete a diet plan' })
  @ApiResponse({ status: 200, description: 'Diet plan deleted successfully' })
  async deleteDietPlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.deleteDietPlan(context, BigInt(id));
  }

  @Post('diet-plans/:id/apply')
  @ApiOperation({ summary: 'Apply a diet plan to create logs' })
  @ApiResponse({ status: 200, description: 'Diet plan applied successfully' })
  async applyDietPlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() applyDto: ApplyPlanDto,
  ) {
    const context = await this.resolveContext(user, applyDto.elderUserId);
    return this.lifestyleService.applyDietPlan(context, BigInt(id), applyDto);
  }

  @Get('diet-plans/:id/compliance')
  @ApiOperation({ summary: 'Get diet plan compliance data' })
  @ApiResponse({
    status: 200,
    description: 'Plan compliance data',
    type: PlanComplianceResponseDto,
  })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  async getDietPlanCompliance(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    return this.lifestyleService.getDietPlanCompliance(context, BigInt(id), start, end);
  }

  // ============================================
  // Exercise Plan Endpoints
  // ============================================

  @Post('exercise-plans')
  @ApiOperation({ summary: 'Create an exercise plan' })
  @ApiResponse({ status: 201, description: 'Exercise plan created successfully' })
  async createExercisePlan(@CurrentUser() user: any, @Body() createDto: CreateExercisePlanDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.lifestyleService.createExercisePlan(context, createDto);
  }

  @Get('exercise-plans')
  @ApiOperation({ summary: 'Get all exercise plans' })
  @ApiResponse({ status: 200, description: 'List of exercise plans' })
  async findAllExercisePlans(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findAllExercisePlans(context);
  }

  @Get('exercise-plans/:id')
  @ApiOperation({ summary: 'Get an exercise plan by ID' })
  @ApiResponse({ status: 200, description: 'Exercise plan details' })
  async findExercisePlanById(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.findExercisePlanById(context, BigInt(id));
  }

  @Put('exercise-plans/:id')
  @ApiOperation({ summary: 'Update an exercise plan' })
  @ApiResponse({ status: 200, description: 'Exercise plan updated successfully' })
  async updateExercisePlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() updateDto: UpdateExercisePlanDto,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId || updateDto.elderUserId);
    return this.lifestyleService.updateExercisePlan(context, BigInt(id), updateDto);
  }

  @Delete('exercise-plans/:id')
  @ApiOperation({ summary: 'Delete an exercise plan' })
  @ApiResponse({ status: 200, description: 'Exercise plan deleted successfully' })
  async deleteExercisePlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.lifestyleService.deleteExercisePlan(context, BigInt(id));
  }

  @Post('exercise-plans/:id/apply')
  @ApiOperation({ summary: 'Apply an exercise plan to create logs' })
  @ApiResponse({ status: 200, description: 'Exercise plan applied successfully' })
  async applyExercisePlan(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() applyDto: ApplyPlanDto,
  ) {
    const context = await this.resolveContext(user, applyDto.elderUserId);
    return this.lifestyleService.applyExercisePlan(context, BigInt(id), applyDto);
  }

  @Get('exercise-plans/:id/compliance')
  @ApiOperation({ summary: 'Get exercise plan compliance data' })
  @ApiResponse({
    status: 200,
    description: 'Plan compliance data',
    type: PlanComplianceResponseDto,
  })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  async getExercisePlanCompliance(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();
    return this.lifestyleService.getExercisePlanCompliance(context, BigInt(id), start, end);
  }
}

