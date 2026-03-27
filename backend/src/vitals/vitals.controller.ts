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
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { VitalsService } from './vitals.service';
import { CreateVitalDto, VitalType } from './dto/create-vital.dto';
import { UpdateVitalDto } from './dto/update-vital.dto';
import { GetVitalsTrendsDto } from './dto/get-vitals-trends.dto';
import { GetVitalsDto, GetRecentVitalsDto } from './dto/get-vitals.dto';
import { BaseQueryDto } from '../common/dto/base-query.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessControlService } from '../common/services/access-control.service';


@ApiTags('Vitals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('vitals')
export class VitalsController {
  constructor(
    private readonly vitalsService: VitalsService,
    private readonly accessControlService: AccessControlService,
  ) { }

  private async resolveContext(user: any, elderUserId?: string) {
    return this.accessControlService.resolveActorContext(user, elderUserId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new vital measurement' })
  @ApiResponse({ status: 201, description: 'Vital measurement created successfully' })
  async create(@CurrentUser() user: any, @Body() createDto: CreateVitalDto) {
    try {
      // Ensure elderUserId is a string if provided
      const elderUserId = createDto.elderUserId
        ? String(createDto.elderUserId)
        : undefined;
      const context = await this.resolveContext(user, elderUserId);
      return this.vitalsService.create(context, createDto);
    } catch (error) {
      console.error('Error creating vital:', error);
      throw error;
    }
  }

  @Get()
  @ApiOperation({ summary: 'Get all vital measurements for the current user' })
  @ApiQuery({ name: 'type', enum: VitalType, required: false })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  @ApiQuery({ name: 'elderUserId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of vital measurements' })
  async findAll(
    @CurrentUser() user: any,
    @Query() query: GetVitalsDto,
  ) {
    const context = await this.resolveContext(user, query.elderUserId);
    return this.vitalsService.findAll(
      context,
      query.type,
      query.startDate ? new Date(query.startDate) : undefined,
      query.endDate ? new Date(query.endDate) : undefined,
    );
  }
  
  @Get('recent')
  @ApiOperation({ summary: 'Get recent vital measurements with dynamic limit' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'type', enum: VitalType, required: false })
  @ApiQuery({ name: 'elderUserId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of recent vital measurements' })
  async getRecent(
    @CurrentUser() user: any,
    @Query() query: GetRecentVitalsDto,
  ) {
    const context = await this.resolveContext(user, query.elderUserId);
    return this.vitalsService.getRecent(context, query.limit, query.type);
  }

  @Get('latest')

  @ApiOperation({ summary: 'Get latest vital measurements per kind' })
  @ApiResponse({ status: 200, description: 'Latest vital measurements' })
  async getLatest(
    @CurrentUser() user: any,
    @Query() query?: BaseQueryDto,
  ) {
    const context = await this.resolveContext(user, query?.elderUserId);
    return this.vitalsService.getLatest(context);
  }

  @Get('trends')
  @ApiOperation({ summary: 'Get trends for vital measurements' })
  @ApiQuery({ name: 'kindCode', required: false, type: String })
  @ApiQuery({ name: 'period', required: false, type: String, description: 'weekly or monthly' })
  @ApiQuery({ name: 'days', required: false, type: String })
  @ApiQuery({ name: 'elderUserId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Trend data' })
  async getTrends(
    @CurrentUser() user: any,
    @Query() query: GetVitalsTrendsDto,
  ) {
    const { kindCode, period, days, elderUserId } = query;
    const context = await this.resolveContext(user, elderUserId);
    const daysNum = days || (period === 'monthly' ? 30 : 7);
    return this.vitalsService.getTrends(context, kindCode, daysNum);
  }

  @Get('abnormal')
  @ApiOperation({ summary: 'Get abnormal vital readings' })
  @ApiResponse({ status: 200, description: 'List of abnormal readings' })
  async getAbnormal(
    @CurrentUser() user: any,
    @Query() query?: BaseQueryDto,
  ) {
    const context = await this.resolveContext(user, query?.elderUserId);
    return this.vitalsService.getAbnormal(context);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a vital measurement by ID' })
  @ApiResponse({ status: 200, description: 'Vital measurement details' })
  @ApiResponse({ status: 404, description: 'Vital measurement not found' })
  async findOne(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query() query?: BaseQueryDto,
  ) {
    const context = await this.resolveContext(user, query?.elderUserId);
    return this.vitalsService.findOne(context, BigInt(id));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a vital measurement' })
  @ApiResponse({ status: 200, description: 'Vital measurement updated successfully' })
  @ApiResponse({ status: 404, description: 'Vital measurement not found' })
  async update(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() updateDto: UpdateVitalDto,
  ) {
    const context = await this.resolveContext(user, updateDto.elderUserId);
    return this.vitalsService.update(context, BigInt(id), updateDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a vital measurement' })
  @ApiResponse({ status: 200, description: 'Vital measurement deleted successfully' })
  @ApiResponse({ status: 404, description: 'Vital measurement not found' })
  async remove(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query() query?: BaseQueryDto,
  ) {
    const context = await this.resolveContext(user, query?.elderUserId);
    return this.vitalsService.remove(context, BigInt(id));
  }
}

