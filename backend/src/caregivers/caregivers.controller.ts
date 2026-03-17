// @ts-nocheck
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Patch,
  UseGuards,
  ParseIntPipe,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { CaregiversService } from './caregivers.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';
import { AcceptInvitationByCodeDto } from './dto/accept-invitation-by-code.dto';
import { ToggleStatusDto } from './dto/toggle-status.dto';
import { ContactCaregiverDto } from './dto/contact-caregiver.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Caregivers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('caregivers')
export class CaregiversController {
  constructor(private readonly caregiversService: CaregiversService) {}

  @Get()
  @ApiOperation({ summary: 'Get all caregivers for the current user' })
  @ApiResponse({ status: 200, description: 'List of caregivers' })
  findAll(@CurrentUser() user: any) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.findAll(userId);
  }

  @Get('all')
  @ApiOperation({ summary: 'Get global list of caregivers and assignments' })
  @ApiResponse({ status: 200, description: 'Global caregivers list' })
  getAllCaregivers() {
    return this.caregiversService.findAllCaregivers();
  }

  @Get('assignments')
  @ApiOperation({ summary: 'Get all elder assignments for the current caregiver user' })
  @ApiResponse({ status: 200, description: 'List of caregiver assignments' })
  getAssignments(@CurrentUser() user: any) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.findAssignmentsForCaregiver(userId);
  }

  @Post(':id/contact')
  @ApiOperation({ summary: 'Contact a caregiver' })
  @ApiResponse({ status: 200, description: 'Caregiver contacted successfully' })
  @ApiResponse({ status: 404, description: 'Caregiver not found' })
  contactCaregiver(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() contactDto: ContactCaregiverDto,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    console.log('📬 CONTACT CAREGIVER REQUEST');
    console.log('  UserID:', userId);
    console.log('  AssignmentID (raw):', id);
    console.log('  Message Length:', contactDto.message.length);
    return this.caregiversService.contactCaregiver(
      userId,
      BigInt(id),
      contactDto,
    );
  }

  @Post('invitations')
  @ApiOperation({ summary: 'Send caregiver invitation' })
  @ApiResponse({ status: 201, description: 'Invitation sent successfully' })
  sendInvitation(@CurrentUser() user: any, @Body() createDto: CreateInvitationDto) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.sendInvitation(userId, createDto);
  }

  @Get('invitations')
  @ApiOperation({ summary: 'Get all pending invitations' })
  @ApiResponse({ status: 200, description: 'List of invitations' })
  getInvitations(@CurrentUser() user: any) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.getInvitations(userId);
  }

  @Get('invitations/pending')
  @ApiOperation({ summary: 'Get pending invitations for logged-in caregiver' })
  @ApiResponse({ status: 200, description: 'List of pending invitations' })
  getPendingInvitations(@CurrentUser() user: any) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.getPendingInvitationsForCaregiver(userId);
  }

  @Get('invitations/:code')
  @ApiOperation({ summary: 'Get invitation by code' })
  @ApiResponse({ status: 200, description: 'Invitation details' })
  @ApiResponse({ status: 404, description: 'Invitation not found' })
  getInvitationByCode(@Param('code') code: string) {
    return this.caregiversService.getInvitationByCode(code);
  }

  @Post('invitations/:id/accept')
  @ApiOperation({ summary: 'Accept caregiver invitation' })
  @ApiResponse({ status: 200, description: 'Invitation accepted successfully' })
  @ApiResponse({ status: 404, description: 'Invitation not found' })
  acceptInvitation(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: string) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.acceptInvitation(userId, BigInt(id));
  }

  @Post('invitations/accept-by-code')
  @ApiOperation({ summary: 'Accept caregiver invitation by code' })
  @ApiResponse({ status: 200, description: 'Invitation accepted successfully' })
  @ApiResponse({ status: 404, description: 'Invitation not found' })
  acceptInvitationByCode(
    @CurrentUser() user: any,
    @Body() body: AcceptInvitationByCodeDto,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.acceptInvitationByCode(userId, body.inviteCode);
  }

  @Post('invitations/:id/decline')
  @ApiOperation({ summary: 'Decline caregiver invitation' })
  @ApiResponse({ status: 200, description: 'Invitation declined successfully' })
  @ApiResponse({ status: 404, description: 'Invitation not found' })
  declineInvitation(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: string) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.declineInvitation(userId, BigInt(id));
  }

  @Delete('invitations/:id')
  @ApiOperation({ summary: 'Cancel/Remove caregiver invitation' })
  @ApiResponse({ status: 200, description: 'Invitation removed successfully' })
  @ApiResponse({ status: 404, description: 'Invitation not found' })
  removeInvitation(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: string) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.removeInvitation(userId, BigInt(id));
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove caregiver assignment' })
  @ApiResponse({ status: 200, description: 'Caregiver removed successfully' })
  @ApiResponse({ status: 404, description: 'Caregiver assignment not found' })
  remove(@CurrentUser() user: any, @Param('id', ParseIntPipe) id: string) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.caregiversService.remove(userId, BigInt(id));
  }


  @Patch(':id/toggle-status')
  @ApiOperation({ summary: 'Toggle caregiver assignment activity status' })
  @ApiResponse({ status: 200, description: 'Status toggled successfully' })
  @ApiResponse({ status: 404, description: 'Caregiver assignment not found' })
  toggleStatus(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Body() body: ToggleStatusDto,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    console.log('🚀 TOGGLE STATUS REQUEST');
    console.log('  UserID:', userId);
    console.log('  AssignmentID (raw):', id);
    console.log('  IsActive:', body.isActive);
    return this.caregiversService.toggleStatus(userId, BigInt(id), body.isActive);
  }
}

