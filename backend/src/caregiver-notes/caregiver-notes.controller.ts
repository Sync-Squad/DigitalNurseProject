import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UseGuards,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { CaregiverNotesService } from './caregiver-notes.service';
import { CreateCaregiverNoteDto } from './dto/create-caregiver-note.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessControlService } from '../common/services/access-control.service';

@ApiTags('Caregiver Notes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('caregiver-notes')
export class CaregiverNotesController {
  constructor(
    private readonly caregiverNotesService: CaregiverNotesService,
    private readonly accessControlService: AccessControlService,
  ) {}

  private async resolveContext(user: any, elderUserId?: string) {
    return this.accessControlService.resolveActorContext(user, elderUserId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a caregiver note' })
  @ApiResponse({ status: 201, description: 'Note created successfully' })
  async create(@CurrentUser() user: any, @Body() createDto: CreateCaregiverNoteDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.caregiverNotesService.create(context, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all caregiver notes for a patient' })
  @ApiQuery({ name: 'elderUserId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of caregiver notes' })
  async findAll(@CurrentUser() user: any, @Query('elderUserId') elderUserId?: string) {
    const context = await this.resolveContext(user, elderUserId);
    return this.caregiverNotesService.findAll(context);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a caregiver note by ID' })
  @ApiResponse({ status: 200, description: 'Note details' })
  @ApiResponse({ status: 404, description: 'Note not found' })
  async findOne(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.caregiverNotesService.findOne(context, BigInt(id));
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a caregiver note' })
  @ApiResponse({ status: 200, description: 'Note deleted successfully' })
  @ApiResponse({ status: 404, description: 'Note not found' })
  async remove(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.caregiverNotesService.remove(context, BigInt(id));
  }
}

