// @ts-nocheck
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { MedicationsService } from './medications.service';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { UpdateMedicationDto } from './dto/update-medication.dto';
import { LogIntakeDto } from './dto/log-intake.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessControlService } from '../common/services/access-control.service';

@ApiTags('Medications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('medications')
export class MedicationsController {
  constructor(
    private readonly medicationsService: MedicationsService,
    private readonly accessControlService: AccessControlService,
  ) {}

  private async resolveContext(user: any, elderUserId?: string) {
    return this.accessControlService.resolveActorContext(user, elderUserId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new medication' })
  @ApiResponse({ status: 201, description: 'Medication created successfully' })
  async create(@CurrentUser() user: any, @Body() createDto: CreateMedicationDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.medicationsService.create(context, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all medications for the current user' })
  @ApiResponse({ status: 200, description: 'List of medications' })
  async findAll(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.findAll(context);
  }

  @Get('upcoming')
  @ApiOperation({ summary: 'Get upcoming medication reminders' })
  @ApiResponse({ status: 200, description: 'List of upcoming reminders' })
  async getUpcomingReminders(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.getUpcomingReminders(context);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a medication by ID' })
  @ApiResponse({ status: 200, description: 'Medication details' })
  @ApiResponse({ status: 404, description: 'Medication not found' })
  async findOne(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.findOne(context, BigInt(id));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a medication' })
  @ApiResponse({ status: 200, description: 'Medication updated successfully' })
  @ApiResponse({ status: 404, description: 'Medication not found' })
  async update(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() updateDto: UpdateMedicationDto,
  ) {
    const context = await this.resolveContext(user, updateDto.elderUserId);
    return this.medicationsService.update(context, BigInt(id), updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a medication' })
  @ApiResponse({ status: 200, description: 'Medication deleted successfully' })
  @ApiResponse({ status: 404, description: 'Medication not found' })
  async remove(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.remove(context, BigInt(id));
  }

  @Get(':id/intakes')
  @ApiOperation({ summary: 'Get intake history for a medication' })
  @ApiResponse({ status: 200, description: 'List of intakes' })
  async getIntakeHistory(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.getIntakeHistory(context, BigInt(id));
  }

  @Post(':id/intakes')
  @ApiOperation({ summary: 'Log medication intake' })
  @ApiResponse({ status: 201, description: 'Intake logged successfully' })
  async logIntake(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() logDto: LogIntakeDto,
  ) {
    const context = await this.resolveContext(user, logDto.elderUserId);
    return this.medicationsService.logIntake(context, BigInt(id), logDto);
  }

  @Get(':id/adherence')
  @ApiOperation({ summary: 'Get medication adherence percentage' })
  @ApiResponse({ status: 200, description: 'Adherence percentage' })
  async getAdherence(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('days') days?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.medicationsService.calculateAdherence(
      context,
      days ? parseInt(days, 10) : 7,
    );
  }

  @Get(':id/streak')
  @ApiOperation({ summary: 'Get medication adherence streak' })
  @ApiResponse({ status: 200, description: 'Adherence streak' })
  async getAdherenceStreak(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return { streak: 0 }; // Placeholder
  }

  @Get('adherence')
  @ApiOperation({ summary: 'Get period-based medication adherence for all medications' })
  @ApiResponse({ status: 200, description: 'Period adherence data' })
  async getPeriodAdherence(
    @CurrentUser() user: any,
    @Query('period') period?: string,
    @Query('days') days?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    const daysNum = days ? parseInt(days, 10) : period === 'monthly' ? 30 : 7;
    return this.medicationsService.calculateAdherence(context, daysNum);
  }

  @Get('status')
  @ApiOperation({ summary: 'Get medication status for a specific date' })
  @ApiResponse({ status: 200, description: 'Medication status' })
  async getMedicationStatus(
    @CurrentUser() user: any,
    @Query('date') date?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    const targetDate = date ? new Date(date) : new Date();
    return this.medicationsService.getMedicationStatus(context, targetDate);
  }
}
