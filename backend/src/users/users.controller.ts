// @ts-nocheck
import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  UseGuards,
  Param,
  UseInterceptors,
  UploadedFile,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { User } from '@prisma/client';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
} from '@nestjs/swagger';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) { }

  @Get('profile')
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Profile retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getProfile(@CurrentUser() user: any, @Req() req: Request) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return this.usersService.getProfile(userId, baseUrl);
  }

  @Get('patients')
  @ApiOperation({ summary: 'Get all patients with risk and activity info' })
  @ApiResponse({ status: 200, description: 'Patients retrieved successfully' })
  async getPatients(@CurrentUser() user: any) {
    return this.usersService.getPatientsList(user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user details by ID' })
  @ApiResponse({ status: 200, description: 'User details retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUserById(@Param('id') id: string, @Req() req: Request) {
    const userId = BigInt(id);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return this.usersService.getProfile(userId, baseUrl);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update user profile' })
  @ApiResponse({ status: 200, description: 'Profile updated successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async updateProfile(
    @CurrentUser() user: any,
    @Body() updateProfileDto: UpdateProfileDto,
    @Req() req: Request,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return this.usersService.updateProfile(userId, updateProfileDto, baseUrl);
  }

  @Post('complete-profile')
  @ApiOperation({ summary: 'Complete user profile during onboarding' })
  @ApiResponse({ status: 200, description: 'Profile completed successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async completeProfile(
    @CurrentUser() user: any,
    @Body() completeProfileDto: CompleteProfileDto,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.usersService.completeProfile(userId, completeProfileDto);
  }

  @Post('profile/avatar')
  @ApiOperation({ summary: 'Upload profile picture' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 200, description: 'Avatar uploaded successfully' })
  @UseInterceptors(FileInterceptor('avatar'))
  async uploadAvatar(@CurrentUser() user: any, @UploadedFile() file: any, @Req() req: Request) {
    if (!file) {
      throw new Error('Avatar file is required');
    }
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return this.usersService.uploadAvatar(userId, file, baseUrl);
  }

  @Patch('change-password')
  @ApiOperation({ summary: 'Change user password' })
  @ApiResponse({ status: 200, description: 'Password changed successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 400, description: 'Invalid old password or mismatching new passwords' })
  async changePassword(
    @CurrentUser() user: any,
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    const userId = typeof user.userId === 'bigint' ? user.userId : BigInt(user.userId);
    return this.usersService.changePassword(userId, changePasswordDto);
  }
}
