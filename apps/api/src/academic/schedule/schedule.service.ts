import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTeacherSubjectDto } from './dto/create-teacher-subject.dto';
import { QueryTeacherSubjectDto } from './dto/query-teacher-subject.dto';
import { CreateScheduleDto } from './dto/create-schedule.dto';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { Day } from '@prisma/client';

@Injectable()
export class ScheduleService {
  private readonly dayMap: Record<string, Day> = {
    Sunday: Day.SENIN,
    Monday: Day.SENIN,
    Tuesday: Day.SELASA,
    Wednesday: Day.RABU,
    Thursday: Day.KAMIS,
    Friday: Day.JUMAT,
    Saturday: Day.SABTU,
  };

  constructor(private prisma: PrismaService) {}

  private getTodayDay(): Day {
    const englishDay = new Date().toLocaleDateString('en-US', {
      weekday: 'long',
    });
    return this.dayMap[englishDay] || Day.SENIN;
  }

  async assignTeacherSubject(dto: CreateTeacherSubjectDto) {
    const existing = await this.prisma.teacherSubject.findUnique({
      where: {
        teacherId_subjectId_classId: {
          teacherId: dto.teacherId,
          subjectId: dto.subjectId,
          classId: dto.classId,
        },
      },
    });
    if (existing) throw new ConflictException('Teacher already assigned to this subject and class');

    return this.prisma.teacherSubject.create({
      data: dto,
      include: {
        teacher: { select: { id: true, name: true, nip: true } },
        subject: true,
        class: { include: { grade: true } },
      },
    });
  }

  async removeTeacherSubject(id: string) {
    await this.findTeacherSubjectOrThrow(id);
    await this.prisma.teacherSubject.delete({ where: { id } });
    return { message: 'Teacher subject assignment removed successfully' };
  }

  async getTeacherSubjects(query: QueryTeacherSubjectDto) {
    const where: any = {};
    if (query.teacherId) where.teacherId = query.teacherId;
    if (query.classId) where.classId = query.classId;
    if (query.subjectId) where.subjectId = query.subjectId;

    return this.prisma.teacherSubject.findMany({
      where,
      include: {
        teacher: { select: { id: true, name: true, nip: true } },
        subject: true,
        class: { include: { grade: true } },
        _count: { select: { schedules: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createSchedule(dto: CreateScheduleDto) {
    await this.findTeacherSubjectOrThrow(dto.teacherSubjectId);

    return this.prisma.schedule.create({
      data: dto,
      include: {
        teacherSubject: {
          include: {
            teacher: { select: { id: true, name: true, nip: true } },
            subject: true,
            class: { include: { grade: true } },
          },
        },
      },
    });
  }

  async updateSchedule(id: string, dto: UpdateScheduleDto) {
    await this.findScheduleOrThrow(id);
    return this.prisma.schedule.update({
      where: { id },
      data: dto,
      include: {
        teacherSubject: {
          include: {
            teacher: { select: { id: true, name: true, nip: true } },
            subject: true,
            class: { include: { grade: true } },
          },
        },
      },
    });
  }

  async deleteSchedule(id: string) {
    await this.findScheduleOrThrow(id);
    await this.prisma.schedule.delete({ where: { id } });
    return { message: 'Schedule deleted successfully' };
  }

  async getScheduleByClass(classId: string, day?: Day) {
    const where: any = {
      teacherSubject: { classId },
      isActive: true,
    };
    if (day) where.day = day;

    return this.prisma.schedule.findMany({
      where,
      include: {
        teacherSubject: {
          include: {
            teacher: { select: { id: true, name: true, nip: true } },
            subject: true,
          },
        },
      },
      orderBy: [{ day: 'asc' }, { startTime: 'asc' }],
    });
  }

  async getScheduleByTeacher(teacherId: string, day?: Day) {
    const where: any = {
      teacherSubject: { teacherId },
      isActive: true,
    };
    if (day) where.day = day;

    return this.prisma.schedule.findMany({
      where,
      include: {
        teacherSubject: {
          include: {
            subject: true,
            class: { include: { grade: true } },
          },
        },
      },
      orderBy: [{ day: 'asc' }, { startTime: 'asc' }],
    });
  }

  async getTodayScheduleByClass(classId: string) {
    return this.getScheduleByClass(classId, this.getTodayDay());
  }

  async getTodayScheduleByTeacher(teacherId: string) {
    return this.getScheduleByTeacher(teacherId, this.getTodayDay());
  }

  private async findTeacherSubjectOrThrow(id: string) {
    const ts = await this.prisma.teacherSubject.findUnique({ where: { id } });
    if (!ts) throw new NotFoundException('Teacher subject assignment not found');
    return ts;
  }

  private async findScheduleOrThrow(id: string) {
    const s = await this.prisma.schedule.findUnique({ where: { id } });
    if (!s) throw new NotFoundException('Schedule not found');
    return s;
  }
}
