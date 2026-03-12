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
import { NotificationsService } from './notifications.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessControlService } from '../common/services/access-control.service';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly accessControlService: AccessControlService,
  ) {}

  private async resolveContext(user: any, elderUserId?: string) {
    return this.accessControlService.resolveActorContext(user, elderUserId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a notification' })
  @ApiResponse({ status: 201, description: 'Notification created successfully' })
  async create(@CurrentUser() user: any, @Body() createDto: CreateNotificationDto) {
    const context = await this.resolveContext(user, createDto.elderUserId);
    return this.notificationsService.create(context, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all notifications for the current user' })
  @ApiQuery({ name: 'isRead', required: false, type: Boolean })
  @ApiQuery({ name: 'type', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  @ApiQuery({ name: 'elderUserId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of notifications' })
  async findAll(
    @CurrentUser() user: any,
    @Query('isRead') isRead?: string,
    @Query('type') type?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    const isReadBool = isRead === 'true' ? true : isRead === 'false' ? false : undefined;
    return this.notificationsService.findAll(
      context,
      isReadBool,
      type,
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
    );
  }

  @Get('unread')
  @ApiOperation({ summary: 'Get unread notifications' })
  @ApiResponse({ status: 200, description: 'List of unread notifications' })
  async getUnread(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.notificationsService.getUnread(context);
  }

  @Get('unread/count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200, description: 'Unread count' })
  async getUnreadCount(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.notificationsService.getUnreadCount(context);
  }

  @Post(':id/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiResponse({ status: 200, description: 'Notification marked as read' })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async markAsRead(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.notificationsService.markAsRead(context, BigInt(id));
  }

  @Post('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({ status: 200, description: 'All notifications marked as read' })
  async markAllAsRead(
    @CurrentUser() user: any,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.notificationsService.markAllAsRead(context);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  @ApiResponse({ status: 200, description: 'Notification deleted successfully' })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async remove(
    @CurrentUser() user: any,
    @Param('id', ParseIntPipe) id: string,
    @Query('elderUserId') elderUserId?: string,
  ) {
    const context = await this.resolveContext(user, elderUserId);
    return this.notificationsService.remove(context, BigInt(id));
  }
}

