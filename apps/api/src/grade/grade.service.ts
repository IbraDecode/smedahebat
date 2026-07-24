import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateComponentDto } from './dto/create-component.dto';
import { UpdateComponentDto } from './dto/update-component.dto';
import { InputScoreDto } from './dto/input-score.dto';
import { InputBulkScoresDto } from './dto/input-bulk-scores.dto';
import { QueryGradeDto } from './dto/query-grade.dto';
import { GenerateRaporDto } from './dto/generate-rapor.dto';

@Injectable()
export class GradeService {
  constructor(private prisma: PrismaService) {}

  // ── Grade Components ──────────────────────────────────

  async createComponent(dto: CreateComponentDto) {
    return this.prisma.gradeComponent.create({
      data: {
        name: dto.name,
        type: dto.type,
        weight: dto.weight ?? 100,
        maxScore: dto.maxScore ?? 100,
        description: dto.description,
        subjectId: dto.subjectId,
        classId: dto.classId,
        academicYearId: dto.academicYearId,
      },
      include: {
        subject: true,
        class: true,
        academicYear: true,
      },
    });
  }

  async getComponents(query: QueryGradeDto) {
    const where: any = {};
    if (query.subjectId) where.subjectId = query.subjectId;
    if (query.classId) where.classId = query.classId;
    if (query.academicYearId) where.academicYearId = query.academicYearId;

    return this.prisma.gradeComponent.findMany({
      where,
      include: {
        subject: true,
        class: true,
        academicYear: true,
        _count: { select: { scores: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateComponent(id: string, dto: UpdateComponentDto) {
    await this.findComponentOrThrow(id);
    return this.prisma.gradeComponent.update({
      where: { id },
      data: dto,
      include: {
        subject: true,
        class: true,
        academicYear: true,
      },
    });
  }

  async deleteComponent(id: string) {
    await this.findComponentOrThrow(id);
    await this.prisma.gradeComponent.delete({ where: { id } });
    return { message: 'Grade component deleted successfully' };
  }

  // ── Scores ────────────────────────────────────────────

  async inputScore(dto: InputScoreDto) {
    await this.findComponentOrThrow(dto.componentId);

    const existing = await this.prisma.score.findUnique({
      where: {
        componentId_studentId: {
          componentId: dto.componentId,
          studentId: dto.studentId,
        },
      },
    });

    if (existing) {
      return this.prisma.score.update({
        where: { id: existing.id },
        data: { score: dto.score, notes: dto.notes },
        include: { component: true, student: { select: { id: true, name: true, nis: true } } },
      });
    }

    return this.prisma.score.create({
      data: dto,
      include: { component: true, student: { select: { id: true, name: true, nis: true } } },
    });
  }

  async inputBulkScores(dto: InputBulkScoresDto) {
    await this.findComponentOrThrow(dto.componentId);

    const results = [];
    for (const item of dto.scores) {
      const existing = await this.prisma.score.findUnique({
        where: {
          componentId_studentId: {
            componentId: dto.componentId,
            studentId: item.studentId,
          },
        },
      });

      if (existing) {
        const updated = await this.prisma.score.update({
          where: { id: existing.id },
          data: { score: item.score, notes: item.notes },
        });
        results.push(updated);
      } else {
        const created = await this.prisma.score.create({
          data: {
            componentId: dto.componentId,
            studentId: item.studentId,
            score: item.score,
            notes: item.notes,
          },
        });
        results.push(created);
      }
    }

    return { count: results.length, scores: results };
  }

  async getScoresByComponent(componentId: string) {
    await this.findComponentOrThrow(componentId);
    return this.prisma.score.findMany({
      where: { componentId },
      include: {
        student: { select: { id: true, name: true, nis: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getScoresByStudent(studentId: string, query: QueryGradeDto) {
    const where: any = { studentId };

    if (query.subjectId || query.classId || query.academicYearId) {
      where.component = {};
      if (query.subjectId) where.component.subjectId = query.subjectId;
      if (query.classId) where.component.classId = query.classId;
      if (query.academicYearId) where.component.academicYearId = query.academicYearId;
    }

    return this.prisma.score.findMany({
      where,
      include: {
        component: {
          include: { subject: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getStudentSubjectScores(studentId: string, subjectId: string) {
    const components = await this.prisma.gradeComponent.findMany({
      where: { subjectId },
      include: {
        scores: {
          where: { studentId },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return components.map((c) => ({
      componentId: c.id,
      componentName: c.name,
      componentType: c.type,
      weight: c.weight,
      maxScore: c.maxScore,
      score: c.scores.length > 0 ? c.scores[0].score : null,
      scoreId: c.scores.length > 0 ? c.scores[0].id : null,
      notes: c.scores.length > 0 ? c.scores[0].notes : null,
    }));
  }

  async calculateFinalScore(studentId: string, subjectId: string, classId: string, academicYearId: string) {
    const components = await this.prisma.gradeComponent.findMany({
      where: { subjectId, classId, academicYearId },
    });

    if (components.length === 0) return null;

    let totalWeighted = 0;
    let totalWeight = 0;

    for (const comp of components) {
      const score = await this.prisma.score.findUnique({
        where: {
          componentId_studentId: {
            componentId: comp.id,
            studentId,
          },
        },
      });

      if (score) {
        const normalized = (score.score / comp.maxScore) * 100;
        totalWeighted += normalized * comp.weight;
        totalWeight += comp.weight;
      }
    }

    if (totalWeight === 0) return null;

    const averageScore = totalWeighted / totalWeight;
    return { totalScore: totalWeighted, averageScore };
  }

  // ── Report Card ───────────────────────────────────────

  async generateReportCard(dto: GenerateRaporDto) {
    const students = await this.prisma.user.findMany({
      where: { classId: dto.classId, role: 'SISWA', isActive: true },
      select: { id: true, name: true, nis: true },
    });

    if (students.length === 0) throw new BadRequestException('No students found in this class');

    const subjects = await this.prisma.teacherSubject.findMany({
      where: { classId: dto.classId },
      include: { subject: true },
    });

    const uniqueSubjectIds = [...new Set(subjects.map((s) => s.subjectId))];

    if (uniqueSubjectIds.length === 0) throw new BadRequestException('No subjects assigned to this class');

    const results = [];

    for (const student of students) {
      let reportCard = await this.prisma.reportCard.findUnique({
        where: {
          studentId_classId_academicYearId_semester: {
            studentId: student.id,
            classId: dto.classId,
            academicYearId: dto.academicYearId,
            semester: dto.semester,
          },
        },
      });

      if (reportCard) {
        await this.prisma.reportCardSubject.deleteMany({
          where: { reportCardId: reportCard.id },
        });
      }

      const reportCardData: any = {
        studentId: student.id,
        classId: dto.classId,
        academicYearId: dto.academicYearId,
        semester: dto.semester,
      };

      let grandTotalScore = 0;
      let subjectCount = 0;
      const subjectResults = [];

      for (const subjectId of uniqueSubjectIds) {
        const subjectInfo = subjects.find((s) => s.subjectId === subjectId);
        if (!subjectInfo) continue;

        const finalScore = await this.calculateFinalScore(
          student.id,
          subjectId,
          dto.classId,
          dto.academicYearId,
        );

        const avgScore = finalScore?.averageScore ?? 0;
        const grade = this.calculateGrade(avgScore);
        const description = this.gradeDescription(grade);

        subjectResults.push({
          subjectId,
          totalScore: finalScore?.totalScore ?? 0,
          averageScore: avgScore,
          grade,
          description,
        });

        grandTotalScore += avgScore;
        subjectCount++;
      }

      const overallAvg = subjectCount > 0 ? grandTotalScore / subjectCount : 0;

      if (reportCard) {
        reportCard = await this.prisma.reportCard.update({
          where: { id: reportCard.id },
          data: {
            totalScore: grandTotalScore,
            averageScore: overallAvg,
            rank: null,
          },
        });
      } else {
        reportCard = await this.prisma.reportCard.create({
          data: {
            ...reportCardData,
            totalScore: grandTotalScore,
            averageScore: overallAvg,
          },
        });
      }

      for (const sub of subjectResults) {
        await this.prisma.reportCardSubject.create({
          data: {
            reportCardId: reportCard.id,
            subjectId: sub.subjectId,
            totalScore: sub.totalScore,
            averageScore: sub.averageScore,
            grade: sub.grade,
            description: sub.description,
          },
        });
      }

      results.push({
        student: { id: student.id, name: student.name, nis: student.nis },
        reportCardId: reportCard.id,
        averageScore: overallAvg,
        subjects: subjectResults,
      });
    }

    await this.calculateRanks(dto.classId, dto.academicYearId, dto.semester);

    return { count: results.length, reportCards: results };
  }

  async getReportCard(studentId: string, academicYearId: string, semester: number, classId?: string) {
    if (!classId) {
      const student = await this.prisma.user.findUnique({
        where: { id: studentId },
        select: { classId: true },
      });
      if (!student?.classId) throw new NotFoundException('Student has no class assignment');
      classId = student.classId;
    }

    const reportCard = await this.prisma.reportCard.findUnique({
      where: {
        studentId_classId_academicYearId_semester: {
          studentId,
          classId,
          academicYearId,
          semester,
        },
      },
      include: {
        subjects: {
          include: { subject: true },
        },
        student: { select: { id: true, name: true, nis: true } },
        class: { include: { grade: true } },
        academicYear: true,
      },
    });

    if (!reportCard) throw new NotFoundException('Report card not found');

    return reportCard;
  }

  async getClassReportCards(classId: string, academicYearId: string, semester: number) {
    return this.prisma.reportCard.findMany({
      where: { classId, academicYearId, semester },
      include: {
        subjects: {
          include: { subject: true },
        },
        student: { select: { id: true, name: true, nis: true } },
        class: { include: { grade: true } },
        academicYear: true,
      },
      orderBy: [{ rank: 'asc' }, { averageScore: 'desc' }],
    });
  }

  async publishReportCard(id: string) {
    const reportCard = await this.prisma.reportCard.findUnique({ where: { id } });
    if (!reportCard) throw new NotFoundException('Report card not found');
    if (reportCard.isPublished) throw new BadRequestException('Report card already published');

    return this.prisma.reportCard.update({
      where: { id },
      data: { isPublished: true, publishedAt: new Date() },
    });
  }

  async getGradeSummary(studentId: string, academicYearId: string) {
    const scores = await this.prisma.score.findMany({
      where: {
        studentId,
        component: { academicYearId },
      },
      include: {
        component: {
          include: { subject: true },
        },
      },
    });

    const subjectMap = new Map();
    for (const s of scores) {
      const subId = s.component.subjectId;
      if (!subjectMap.has(subId)) {
        subjectMap.set(subId, {
          subject: s.component.subject,
          components: [],
        });
      }
      subjectMap.get(subId).components.push({
        name: s.component.name,
        type: s.component.type,
        score: s.score,
        maxScore: s.component.maxScore,
        weight: s.component.weight,
      });
    }

    const subjectSummaries = [];
    for (const [_, data] of subjectMap) {
      let totalWeighted = 0;
      let totalWeight = 0;
      for (const c of data.components) {
        const normalized = (c.score / c.maxScore) * 100;
        totalWeighted += normalized * c.weight;
        totalWeight += c.weight;
      }
      const avg = totalWeight > 0 ? totalWeighted / totalWeight : 0;
      subjectSummaries.push({
        subject: data.subject,
        averageScore: Math.round(avg * 100) / 100,
        grade: this.calculateGrade(avg),
        totalComponents: data.components.length,
      });
    }

    const overallAvg =
      subjectSummaries.length > 0
        ? subjectSummaries.reduce((sum, s) => sum + s.averageScore, 0) / subjectSummaries.length
        : 0;

    return {
      totalSubjects: subjectSummaries.length,
      overallAverage: Math.round(overallAvg * 100) / 100,
      overallGrade: this.calculateGrade(overallAvg),
      subjects: subjectSummaries,
    };
  }

  async getRaporById(id: string) {
    const reportCard = await this.prisma.reportCard.findUnique({
      where: { id },
      include: {
        subjects: {
          include: { subject: true },
        },
        student: { select: { id: true, name: true, nis: true } },
        class: { include: { grade: true } },
        academicYear: true,
      },
    });
    if (!reportCard) throw new NotFoundException('Report card not found');
    return reportCard;
  }

  // ── Private helpers ───────────────────────────────────

  private async calculateRanks(classId: string, academicYearId: string, semester: number) {
    const reportCards = await this.prisma.reportCard.findMany({
      where: { classId, academicYearId, semester },
      orderBy: { averageScore: 'desc' },
    });

    for (let i = 0; i < reportCards.length; i++) {
      await this.prisma.reportCard.update({
        where: { id: reportCards[i].id },
        data: { rank: i + 1 },
      });
    }
  }

  private calculateGrade(score: number): string {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'E';
  }

  private gradeDescription(grade: string): string {
    const map: Record<string, string> = {
      A: 'Sangat Baik',
      B: 'Baik',
      C: 'Cukup',
      D: 'Kurang',
      E: 'Sangat Kurang',
    };
    return map[grade] ?? '';
  }

  private async findComponentOrThrow(id: string) {
    const component = await this.prisma.gradeComponent.findUnique({ where: { id } });
    if (!component) throw new NotFoundException('Grade component not found');
    return component;
  }
}
