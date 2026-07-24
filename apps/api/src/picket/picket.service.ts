import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePicketDto } from './dto/create-picket.dto';
import { ChecklistDto } from './dto/checklist.dto';
import { QueryPicketDto } from './dto/query-picket.dto';
import { Role, Day } from '@prisma/client';

const DAY_ORDER: Record<Day, number> = {
  SENIN: 1,
  SELASA: 2,
  RABU: 3,
  KAMIS: 4,
  JUMAT: 5,
  SABTU: 6,
};

@Injectable()
export class PicketService {
  constructor(private prisma: PrismaService) {}

  private getDayName(): Day {
    const days: Day[] = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU'];
    const idx = (new Date().getDay() + 6) % 7;
    return days[idx] || 'SENIN';
  }

  async upsertPicket(dto: CreatePicketDto) {
    const classRecord = await this.prisma.class.findUnique({
      where: { id: dto.classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const students = await this.prisma.user.findMany({
      where: { id: { in: dto.studentIds }, classId: dto.classId, role: Role.SISWA },
    });
    if (students.length !== dto.studentIds.length) {
      throw new BadRequestException('Some students are not found or not in this class');
    }

    const picket = await this.prisma.picket.upsert({
      where: { classId_day: { classId: dto.classId, day: dto.day } },
      create: {
        classId: dto.classId,
        day: dto.day,
        members: {
          create: dto.studentIds.map((studentId) => ({ studentId })),
        },
      },
      update: {
        members: {
          deleteMany: {},
          create: dto.studentIds.map((studentId) => ({ studentId })),
        },
      },
      include: {
        members: {
          include: { student: { select: { id: true, nis: true, name: true, photo: true } } },
        },
      },
    });

    return picket;
  }

  async getPicketsByClass(classId: string, query: QueryPicketDto) {
    const classRecord = await this.prisma.class.findUnique({
      where: { id: classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const where: any = { classId };
    if (query.day) where.day = query.day;

    const pickets = await this.prisma.picket.findMany({
      where,
      include: {
        members: {
          include: { student: { select: { id: true, nis: true, name: true, photo: true } } },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { day: 'asc' },
    });

    const sorted = pickets.sort(
      (a, b) => DAY_ORDER[a.day] - DAY_ORDER[b.day],
    );

    return sorted;
  }

  async getMyPicket(studentId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: studentId },
      select: { classId: true },
    });
    if (!user || !user.classId) {
      throw new BadRequestException('Student is not assigned to any class');
    }

    const memberships = await this.prisma.picketMember.findMany({
      where: { studentId },
      include: {
        picket: {
          include: {
            members: {
              include: { student: { select: { id: true, nis: true, name: true, photo: true } } },
            },
          },
        },
      },
    });

    return memberships.map((m) => ({
      ...m.picket,
      memberId: m.id,
    }));
  }

  async getTodayPicket(classId: string) {
    const classRecord = await this.prisma.class.findUnique({
      where: { id: classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const today = this.getDayName();

    const picket = await this.prisma.picket.findUnique({
      where: { classId_day: { classId, day: today } },
      include: {
        members: {
          include: { student: { select: { id: true, nis: true, name: true, photo: true } } },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!picket) return null;

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    const logs = await this.prisma.picketLog.findMany({
      where: {
        picketId: picket.id,
        date: {
          gte: todayDate,
          lt: new Date(todayDate.getTime() + 86400000),
        },
      },
    });

    const logMap = new Map(logs.map((l) => [l.studentId, l]));

    return {
      ...picket,
      members: picket.members.map((m) => ({
        ...m,
        log: logMap.get(m.studentId) || null,
      })),
    };
  }

  async checklist(picketId: string, studentId: string, dto: ChecklistDto) {
    const picket = await this.prisma.picket.findUnique({
      where: { id: picketId },
    });
    if (!picket) throw new NotFoundException('Picket not found');

    const member = await this.prisma.picketMember.findUnique({
      where: { picketId_studentId: { picketId, studentId } },
    });
    if (!member) {
      throw new ForbiddenException('You are not a member of this picket');
    }

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(todayStart.getTime() + 86400000);

    const log = await this.prisma.picketLog.upsert({
      where: {
        picketId_studentId_date: { picketId, studentId, date: todayStart },
      },
      create: {
        picketId,
        studentId,
        date: todayStart,
        isDone: true,
        doneAt: new Date(),
        note: dto.note || null,
      },
      update: {
        isDone: true,
        doneAt: new Date(),
        note: dto.note || null,
      },
      include: {
        picket: { select: { id: true, day: true } },
        student: { select: { id: true, nis: true, name: true } },
      },
    });

    return log;
  }

  async getHistory(studentId: string, query: QueryPicketDto) {
    const where: any = { studentId };
    if (query.date) {
      const date = new Date(query.date);
      const next = new Date(date.getTime() + 86400000);
      where.date = { gte: date, lt: next };
    }

    const logs = await this.prisma.picketLog.findMany({
      where,
      include: {
        picket: {
          include: {
            class: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { date: 'desc' },
    });

    return logs;
  }

  async getClassHistory(classId: string, query: QueryPicketDto) {
    const classRecord = await this.prisma.class.findUnique({
      where: { id: classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const picketIds = await this.prisma.picket.findMany({
      where: { classId },
      select: { id: true },
    });

    const where: any = {
      picketId: { in: picketIds.map((p) => p.id) },
    };
    if (query.date) {
      const date = new Date(query.date);
      const next = new Date(date.getTime() + 86400000);
      where.date = { gte: date, lt: next };
    }
    if (query.day) {
      where.picket = { day: query.day };
    }

    const logs = await this.prisma.picketLog.findMany({
      where,
      include: {
        picket: { select: { id: true, day: true } },
        student: { select: { id: true, nis: true, name: true, photo: true } },
      },
      orderBy: { date: 'desc' },
    });

    return logs;
  }

  async getStats(classId: string) {
    const classRecord = await this.prisma.class.findUnique({
      where: { id: classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const totalStudents = await this.prisma.user.count({
      where: { classId, role: Role.SISWA, isActive: true },
    });

    const pickets = await this.prisma.picket.findMany({
      where: { classId },
      include: {
        _count: { select: { members: true } },
      },
    });

    const totalPickets = pickets.length;
    const totalAssignments = pickets.reduce((sum, p) => sum + p._count.members, 0);

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(todayStart.getTime() + 86400000);

    const todayLogs = await this.prisma.picketLog.count({
      where: {
        picket: { classId },
        date: { gte: todayStart, lt: todayEnd },
        isDone: true,
      },
    });

    const totalLogs = await this.prisma.picketLog.count({
      where: {
        picket: { classId },
      },
    });

    const doneLogs = await this.prisma.picketLog.count({
      where: {
        picket: { classId },
        isDone: true,
      },
    });

    return {
      totalStudents,
      totalPickets,
      totalAssignments,
      todayDone: todayLogs,
      totalLogs,
      doneLogs,
      complianceRate: totalLogs > 0 ? Math.round((doneLogs / totalLogs) * 100) : 0,
    };
  }

  async deletePicket(id: string) {
    const picket = await this.prisma.picket.findUnique({
      where: { id },
    });
    if (!picket) throw new NotFoundException('Picket not found');

    await this.prisma.picket.delete({ where: { id } });
    return { message: 'Picket deleted successfully' };
  }
}
