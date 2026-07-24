import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { NotificationService } from './notification.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { QueryAnnouncementDto } from './dto/query-announcement.dto';
import { QueryNotificationDto } from './dto/query-notification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Notifications & Announcements')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('api/v1')
export class NotificationController {
  constructor(private notificationService: NotificationService) {}

  @Post('announcements')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Create an announcement' })
  async createAnnouncement(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateAnnouncementDto,
  ) {
    return this.notificationService.createAnnouncement(userId, dto);
  }

  @Get('announcements')
  @ApiOperation({ summary: 'List announcements visible to user' })
  async getAnnouncements(
    @CurrentUser() user: any,
    @Query() query: QueryAnnouncementDto,
  ) {
    return this.notificationService.getAnnouncements(
      user.id,
      user.role,
      user.classId,
      query,
    );
  }

  @Get('announcements/:id')
  @ApiOperation({ summary: 'Get announcement detail and mark as read' })
  async getAnnouncementById(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.notificationService.getAnnouncementById(id, userId);
  }

  @Delete('announcements/:id')
  @ApiOperation({ summary: 'Delete (soft) an announcement' })
  async deleteAnnouncement(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    return this.notificationService.deleteAnnouncement(id, user.id, user.role);
  }

  @Get('notifications')
  @ApiOperation({ summary: 'Get user notifications' })
  async getNotifications(
    @CurrentUser('id') userId: string,
    @Query() query: QueryNotificationDto,
  ) {
    return this.notificationService.getNotifications(userId, query);
  }

  @Patch('notifications/:id/read')
  @ApiOperation({ summary: 'Mark a single notification as read' })
  async markNotificationRead(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.notificationService.markNotificationRead(id, userId);
  }

  @Patch('notifications/read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllNotificationsRead(@CurrentUser('id') userId: string) {
    return this.notificationService.markAllNotificationsRead(userId);
  }

  @Get('notifications/unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  async getUnreadCount(@CurrentUser('id') userId: string) {
    return this.notificationService.getUnreadCount(userId);
  }
}
