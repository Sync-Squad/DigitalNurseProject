import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { ActorContext } from '../common/services/access-control.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create notification
   */
  async create(context: ActorContext, createDto: CreateNotificationDto) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: context.elderUserId,
        title: createDto.title,
        message: createDto.body,
        notificationType: createDto.type,
        scheduledTime: createDto.scheduledTime ? new Date(createDto.scheduledTime) : null,
        actionData: createDto.actionData ? (createDto.actionData as any) : null,
        status: 'pending',
        isRead: false,
        isSent: false,
      },
    });

    return this.mapToResponse(notification);
  }

  /**
   * Find all notifications for a user
   */
  async findAll(
    context: ActorContext,
    isRead?: boolean,
    type?: string,
    startDate?: Date,
    endDate?: Date,
  ) {
    const where: any = { userId: context.elderUserId };
    if (isRead !== undefined) {
      where.isRead = isRead;
    }
    if (type) {
      where.notificationType = type;
    }
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = startDate;
      }
      if (endDate) {
        // Set endDate to end of day
        const endOfDay = new Date(endDate);
        endOfDay.setHours(23, 59, 59, 999);
        where.createdAt.lte = endOfDay;
      }
    }

    const notifications = await this.prisma.notification.findMany({
      where,
      orderBy: {
        createdAt: 'desc',
      },
    });

    return notifications.map((n) => this.mapToResponse(n));
  }

  /**
   * Get unread notifications
   */
  async getUnread(context: ActorContext) {
    const notifications = await this.prisma.notification.findMany({
      where: {
        userId: context.elderUserId,
        isRead: false,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return notifications.map((n) => this.mapToResponse(n));
  }

  /**
   * Get unread count
   */
  async getUnreadCount(context: ActorContext) {
    const count = await this.prisma.notification.count({
      where: {
        userId: context.elderUserId,
        isRead: false,
      },
    });

    return { count };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(context: ActorContext, notificationId: bigint) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        notificationId,
        userId: context.elderUserId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    const updated = await this.prisma.notification.update({
      where: { notificationId },
      data: { isRead: true },
    });

    return this.mapToResponse(updated);
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(context: ActorContext) {
    await this.prisma.notification.updateMany({
      where: {
        userId: context.elderUserId,
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    return { message: 'All notifications marked as read' };
  }

  /**
   * Delete notification
   */
  async remove(context: ActorContext, notificationId: bigint) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        notificationId,
        userId: context.elderUserId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    await this.prisma.notification.delete({
      where: { notificationId },
    });

    return { message: 'Notification deleted successfully' };
  }

  /**
   * Map database model to API response
   */
  private mapToResponse(notification: any) {
    return {
      id: notification.notificationId.toString(),
      title: notification.title,
      body: notification.message,
      type: notification.notificationType,
      timestamp: (notification.scheduledTime || notification.sentTime || notification.createdAt).toISOString(),
      isRead: notification.isRead,
      actionData: notification.actionData ? JSON.stringify(notification.actionData) : null,
    };
  }
}

