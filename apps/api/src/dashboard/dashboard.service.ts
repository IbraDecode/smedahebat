import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getDashboard(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { school: true },
    });

    if (!user) throw new NotFoundException('User not found');

    const greeting = `Halo, ${user.name}`;

    switch (user.role) {
      case Role.SISWA:
        return this.getStudentDashboard(user, greeting);
      case Role.GURU:
      case Role.WALI_KELAS:
        return this.getTeacherDashboard(user, greeting);
      default:
        return this.getAdminDashboard(greeting);
    }
  }

  private async getStudentDashboard(user: any, greeting: string) {
    const schoolId = user.schoolId as string;

    const [subjectCount] = await Promise.all([
      this.prisma.subject.count({ where: { schoolId, isActive: true } }),
    ]);

    return {
      greeting,
      stats: {
        totalSubjects: subjectCount,
        todayTasks: 0,
        monthlyAttendance: 0,
        newAnnouncements: 0,
      },
      todaySchedule: [],
      recentAnnouncements: [],
      upcomingTasks: [],
    };
  }

  private async getTeacherDashboard(user: any, greeting: string) {
    const schoolId = user.schoolId as string;

    const [classCount, subjectCount] = await Promise.all([
      this.prisma.class.count({ where: { schoolId } }),
      this.prisma.subject.count({ where: { schoolId, isActive: true } }),
    ]);

    return {
      greeting,
      stats: {
        totalClasses: classCount,
        totalSubjects: subjectCount,
        todayAttendance: 0,
        pendingGrading: 0,
      },
      todaySchedule: [],
      recentAnnouncements: [],
      upcomingTasks: [],
    };
  }

  private async getAdminDashboard(greeting: string) {
    const [totalStudents, totalTeachers, totalClasses, totalSubjects] =
      await Promise.all([
        this.prisma.user.count({ where: { role: Role.SISWA, isActive: true } }),
        this.prisma.user.count({
          where: {
            OR: [
              { role: Role.GURU },
              { role: Role.WALI_KELAS },
            ],
            isActive: true,
          },
        }),
        this.prisma.class.count(),
        this.prisma.subject.count({ where: { isActive: true } }),
      ]);

    return {
      greeting,
      stats: {
        totalStudents,
        totalTeachers,
        totalClasses,
        totalSubjects,
      },
      todaySchedule: [],
      recentAnnouncements: [],
      upcomingTasks: [],
    };
  }
}
