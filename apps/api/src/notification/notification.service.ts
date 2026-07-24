import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { QueryAnnouncementDto } from './dto/query-announcement.dto';
import { QueryNotificationDto } from './dto/query-notification.dto';
import { AnnouncementTarget, Role } from '@prisma/client';

@Injectable()
export class NotificationService {
  constructor(private prisma: PrismaService) {}

  async createAnnouncement(authorId: string, dto: CreateAnnouncementDto) {
    if (dto.target === AnnouncementTarget.KELAS && !dto.classId) {
      throw new BadRequestException('classId is required when target is KELAS');
    }

    const author = await this.prisma.user.findUnique({
      where: { id: authorId },
      select: { schoolId: true },
    });
    if (!author || !author.schoolId) throw new BadRequestException('Author has no school');

    const announcement = await this.prisma.announcement.create({
      data: {
        schoolId: author.schoolId,
        authorId,
        title: dto.title,
        content: dto.content,
        target: dto.target,
        classId: dto.classId || null,
        isPinned: dto.isPinned ?? false,
        attachment: dto.attachment || null,
      },
      include: {
        author: { select: { id: true, name: true, role: true } },
        class: { select: { id: true, name: true } },
      },
    });

    return announcement;
  }

  async getAnnouncements(
    userId: string,
    role: Role,
    classId: string | undefined,
    query: QueryAnnouncementDto,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { schoolId: true },
    });
    if (!user || !user.schoolId) throw new BadRequestException('User has no school');

    const where: any = {
      schoolId: user.schoolId,
      isActive: true,
    };

    const targetConditions = this.getTargetConditions(role, classId);
    if (targetConditions.length > 0) {
      where.OR = targetConditions;
    }

    if (query.search) {
      where.AND = [
        ...(where.AND || []),
        {
          OR: [
            { title: { contains: query.search, mode: 'insensitive' } },
            { content: { contains: query.search, mode: 'insensitive' } },
          ],
        },
      ];
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.announcement.findMany({
        where,
        include: {
          author: { select: { id: true, name: true, role: true } },
          class: { select: { id: true, name: true } },
          reads: {
            where: { userId },
            select: { id: true, readAt: true },
          },
        },
        skip,
        take: limit,
        orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
      }),
      this.prisma.announcement.count({ where }),
    ]);

    const mapped = data.map((a) => ({
      ...a,
      isRead: a.reads.length > 0,
      readAt: a.reads[0]?.readAt || null,
      reads: undefined,
    }));

    return { data: mapped, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  private getTargetConditions(role: Role, classId?: string): any[] {
    const conditions: any[] = [{ target: AnnouncementTarget.ALL }];

    switch (role) {
      case Role.SISWA:
        conditions.push({ target: AnnouncementTarget.SISWA });
        if (classId) {
          conditions.push({ target: AnnouncementTarget.KELAS, classId });
        }
        break;
      case Role.GURU:
        conditions.push({ target: AnnouncementTarget.GURU });
        break;
      case Role.WALI_KELAS:
        conditions.push({ target: AnnouncementTarget.GURU });
        conditions.push({ target: AnnouncementTarget.WALI_KELAS });
        conditions.push({ target: AnnouncementTarget.SISWA });
        if (classId) {
          conditions.push({ target: AnnouncementTarget.KELAS, classId });
        }
        break;
      default:
        conditions.push(
          { target: AnnouncementTarget.SISWA },
          { target: AnnouncementTarget.GURU },
          { target: AnnouncementTarget.WALI_KELAS },
        );
        if (classId) {
          conditions.push({ target: AnnouncementTarget.KELAS, classId });
        }
        break;
    }

    return conditions;
  }

  async getAnnouncementById(id: string, userId: string) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
      include: {
        author: { select: { id: true, name: true, role: true } },
        class: { select: { id: true, name: true } },
        reads: {
          where: { userId },
          select: { id: true, readAt: true },
        },
      },
    });

    if (!announcement) throw new NotFoundException('Announcement not found');
    if (!announcement.isActive) throw new NotFoundException('Announcement not found');

    const isRead = announcement.reads.length > 0;

    if (!isRead) {
      await this.prisma.announcementRead.create({
        data: { announcementId: id, userId },
      });
    }

    return {
      ...announcement,
      isRead: true,
      readAt: isRead ? announcement.reads[0].readAt : new Date(),
      reads: undefined,
    };
  }

  async deleteAnnouncement(id: string, userId: string, role: Role) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
      select: { id: true, authorId: true },
    });

    if (!announcement) throw new NotFoundException('Announcement not found');

    if (announcement.authorId !== userId && role !== Role.ADMIN) {
      throw new ForbiddenException('You are not allowed to delete this announcement');
    }

    return this.prisma.announcement.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getNotifications(userId: string, query: QueryNotificationDto) {
    const where: any = { userId };

    if (query.isRead !== undefined) {
      where.isRead = query.isRead;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.notification.count({ where }),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async markNotificationRead(id: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, userId },
    });

    if (!notification) throw new NotFoundException('Notification not found');

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllNotificationsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return { message: 'All notifications marked as read' };
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });

    return { unreadCount: count };
  }

  async createNotification(
    userId: string,
    title: string,
    body: string,
    type: string,
    referenceId?: string,
  ) {
    return this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        referenceId: referenceId || null,
      },
    });
  }
}
