import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import * as QRCode from 'qrcode';
import { PrismaService } from '../prisma/prisma.service';
import { GenerateQrDto } from './dto/generate-qr.dto';
import { ScanQrDto } from './dto/scan-qr.dto';
import { QueryAttendanceDto } from './dto/query-attendance.dto';

@Injectable()
export class AttendanceService {
  constructor(private prisma: PrismaService) {}

  async generateQr(teacherId: string, dto: GenerateQrDto) {
    if (!dto.classId && !dto.scheduleId) {
      throw new BadRequestException('Either classId or scheduleId is required');
    }

    const token = crypto.randomUUID();
    const expiresIn = (dto.expiresInMinutes ?? 0.5) * 60 * 1000;
    const expiresAt = new Date(Date.now() + expiresIn);

    let scheduleId: string | null = dto.scheduleId || null;
    let classId: string = dto.classId || '';
    let subjectId: string | null = dto.subjectId || null;

    if (dto.scheduleId) {
      const schedule = await this.prisma.schedule.findUnique({
        where: { id: dto.scheduleId },
        include: { teacherSubject: true },
      });
      if (!schedule) throw new NotFoundException('Schedule not found');
      if (schedule.teacherSubject.teacherId !== teacherId) {
        throw new ForbiddenException('Schedule does not belong to you');
      }
      classId = schedule.teacherSubject.classId;
      subjectId = schedule.teacherSubject.subjectId;
    }

    const session = await this.prisma.attendanceSession.create({
      data: {
        teacherId,
        scheduleId,
        classId,
        subjectId,
        token,
        expiresAt,
        isActive: true,
      },
    });

    const qrDataUrl = await QRCode.toDataURL(token, {
      width: 300,
      margin: 2,
      color: { dark: '#000', light: '#fff' },
    });

    return {
      token: session.token,
      expiresAt: session.expiresAt,
      qrDataUrl,
      sessionId: session.id,
      classId: session.classId,
      subjectId: session.subjectId,
    };
  }

  async validateAndRecord(userId: string, dto: ScanQrDto) {
    const session = await this.prisma.attendanceSession.findUnique({
      where: { token: dto.token },
      include: { class: true },
    });

    if (!session) throw new NotFoundException('QR token is invalid');
    if (!session.isActive) throw new BadRequestException('QR session is no longer active');
    if (new Date() > session.expiresAt) throw new BadRequestException('QR code has expired');

    const student = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!student || !student.classId) {
      throw new BadRequestException('Student class not found');
    }
    if (student.classId !== session.classId) {
      throw new BadRequestException('You are not in the class for this session');
    }

    const existing = await this.prisma.attendance.findUnique({
      where: { sessionId_userId: { sessionId: session.id, userId } },
    });
    if (existing) throw new BadRequestException('You have already recorded attendance for this session');

    const attendance = await this.prisma.attendance.create({
      data: {
        sessionId: session.id,
        userId,
        status: 'HADIR',
        latitude: dto.latitude ?? null,
        longitude: dto.longitude ?? null,
      },
      include: {
        session: {
          include: { class: true },
        },
      },
    });

    return attendance;
  }

  async getSessionStatus(token: string) {
    const session = await this.prisma.attendanceSession.findUnique({
      where: { token },
      include: {
        class: true,
        subject: { select: { id: true, name: true } },
        _count: { select: { attendances: true } },
      },
    });

    if (!session) throw new NotFoundException('Session not found');

    return {
      id: session.id,
      token: session.token,
      isActive: session.isActive && new Date() <= session.expiresAt,
      expiresAt: session.expiresAt,
      class: session.class,
      subject: session.subject,
      totalAttendance: session._count.attendances,
      createdAt: session.createdAt,
    };
  }

  async deactivateSession(teacherId: string, sessionId: string) {
    const session = await this.prisma.attendanceSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) throw new NotFoundException('Session not found');
    if (session.teacherId !== teacherId) throw new ForbiddenException('Not your session');

    return this.prisma.attendanceSession.update({
      where: { id: sessionId },
      data: { isActive: false },
    });
  }

  async getActiveSession(teacherId: string) {
    return this.prisma.attendanceSession.findFirst({
      where: {
        teacherId,
        isActive: true,
        expiresAt: { gte: new Date() },
      },
      include: {
        class: { select: { id: true, name: true } },
        subject: { select: { id: true, name: true } },
        _count: { select: { attendances: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAttendanceByClass(classId: string, query: QueryAttendanceDto) {
    const where: any = { session: { classId } };

    if (query.startDate || query.endDate) {
      where.timestamp = {};
      if (query.startDate) where.timestamp.gte = new Date(query.startDate);
      if (query.endDate) where.timestamp.lte = new Date(query.endDate);
    }

    if (query.status) {
      where.status = query.status;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.attendance.findMany({
        where,
        include: {
          user: { select: { id: true, nis: true, name: true, photo: true } },
          session: {
            select: {
              id: true,
              createdAt: true,
              class: { select: { id: true, name: true } },
              subject: { select: { id: true, name: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
      }),
      this.prisma.attendance.count({ where }),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getAttendanceByStudent(userId: string, query: QueryAttendanceDto) {
    const where: any = { userId };

    if (query.startDate || query.endDate) {
      where.timestamp = {};
      if (query.startDate) where.timestamp.gte = new Date(query.startDate);
      if (query.endDate) where.timestamp.lte = new Date(query.endDate);
    }

    if (query.status) {
      where.status = query.status;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.attendance.findMany({
        where,
        include: {
          session: {
            select: {
              id: true,
              createdAt: true,
              class: { select: { id: true, name: true } },
              subject: { select: { id: true, name: true } },
            },
          },
        },
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
      }),
      this.prisma.attendance.count({ where }),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getAttendanceRecap(classId: string, date?: string) {
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const sessions = await this.prisma.attendanceSession.findMany({
      where: {
        classId,
        createdAt: { gte: startOfDay, lte: endOfDay },
      },
      select: { id: true },
    });

    const sessionIds = sessions.map((s) => s.id);

    const totalStudents = await this.prisma.user.count({
      where: { classId, isActive: true, role: 'SISWA' },
    });

    if (sessionIds.length === 0) {
      return {
        date: targetDate.toISOString().split('T')[0],
        classId,
        totalStudents,
        totalSessions: 0,
        recap: [],
        summary: { HADIR: 0, SAKIT: 0, IZIN: 0, ALPA: 0, TERLAMBAT: 0 },
      };
    }

    const attendances = await this.prisma.attendance.findMany({
      where: { sessionId: { in: sessionIds } },
      include: {
        session: {
          select: {
            id: true,
            createdAt: true,
            subject: { select: { id: true, name: true } },
          },
        },
      },
    });

    const summary = { HADIR: 0, SAKIT: 0, IZIN: 0, ALPA: 0, TERLAMBAT: 0 };
    for (const a of attendances) {
      summary[a.status as keyof typeof summary]++;
    }

    const sessionGroup: Record<string, any> = {};
    for (const a of attendances) {
      const sid = a.sessionId;
      if (!sessionGroup[sid]) {
        sessionGroup[sid] = {
          sessionId: sid,
          subject: a.session.subject,
          createdAt: a.session.createdAt,
          attendances: [],
        };
      }
      sessionGroup[sid].attendances.push(a);
    }

    return {
      date: targetDate.toISOString().split('T')[0],
      classId,
      totalStudents,
      totalSessions: sessions.length,
      totalAttendances: attendances.length,
      recap: Object.values(sessionGroup),
      summary,
    };
  }
}
