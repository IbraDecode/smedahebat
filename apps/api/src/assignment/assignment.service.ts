import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { UpdateAssignmentDto } from './dto/update-assignment.dto';
import { SubmitAssignmentDto } from './dto/submit-assignment.dto';
import { GradeSubmissionDto } from './dto/grade-submission.dto';
import { QueryAssignmentDto } from './dto/query-assignment.dto';
import { Role } from '@prisma/client';

@Injectable()
export class AssignmentService {
  constructor(private prisma: PrismaService) {}

  async createAssignment(teacherId: string, dto: CreateAssignmentDto) {
    const teacher = await this.prisma.user.findUnique({
      where: { id: teacherId },
      select: { schoolId: true },
    });
    if (!teacher || !teacher.schoolId) {
      throw new BadRequestException('Teacher has no school');
    }

    const classRecord = await this.prisma.class.findUnique({
      where: { id: dto.classId },
    });
    if (!classRecord) throw new NotFoundException('Class not found');

    const subject = await this.prisma.subject.findUnique({
      where: { id: dto.subjectId },
    });
    if (!subject) throw new NotFoundException('Subject not found');

    const assignment = await this.prisma.assignment.create({
      data: {
        schoolId: teacher.schoolId,
        teacherId,
        subjectId: dto.subjectId,
        classId: dto.classId,
        title: dto.title,
        description: dto.description || null,
        attachment: dto.attachment || null,
        maxScore: dto.maxScore ?? 100,
        deadline: new Date(dto.deadline),
      },
      include: {
        teacher: { select: { id: true, name: true } },
        subject: { select: { id: true, name: true } },
        class: { select: { id: true, name: true } },
      },
    });

    return assignment;
  }

  async getAssignments(
    userId: string,
    role: Role,
    query: QueryAssignmentDto,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { schoolId: true, classId: true },
    });
    if (!user || !user.schoolId) throw new BadRequestException('User has no school');

    const where: any = {
      schoolId: user.schoolId,
      isActive: true,
    };

    if (role === Role.GURU || role === Role.ADMIN) {
      where.teacherId = userId;
    } else if (role === Role.SISWA) {
      where.classId = user.classId;
    }

    if (query.classId) where.classId = query.classId;
    if (query.subjectId) where.subjectId = query.subjectId;

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.assignment.findMany({
        where,
        include: {
          teacher: { select: { id: true, name: true } },
          subject: { select: { id: true, name: true } },
          class: { select: { id: true, name: true } },
          _count: { select: { submissions: true } },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.assignment.count({ where }),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getAssignmentById(id: string, userId: string, role: Role) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id },
      include: {
        teacher: { select: { id: true, name: true } },
        subject: { select: { id: true, name: true } },
        class: { select: { id: true, name: true } },
        _count: { select: { submissions: true } },
      },
    });

    if (!assignment || !assignment.isActive) {
      throw new NotFoundException('Assignment not found');
    }

    let submission = null;
    if (role === Role.SISWA) {
      submission = await this.prisma.submission.findUnique({
        where: { assignmentId_studentId: { assignmentId: id, studentId: userId } },
      });
    }

    return { ...assignment, submission };
  }

  async updateAssignment(id: string, teacherId: string, dto: UpdateAssignmentDto) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id },
      select: { id: true, teacherId: true },
    });

    if (!assignment) throw new NotFoundException('Assignment not found');
    if (assignment.teacherId !== teacherId) {
      throw new ForbiddenException('You can only update your own assignments');
    }

    const updateData: any = {};
    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.attachment !== undefined) updateData.attachment = dto.attachment;
    if (dto.maxScore !== undefined) updateData.maxScore = dto.maxScore;
    if (dto.deadline !== undefined) updateData.deadline = new Date(dto.deadline);
    if (dto.subjectId !== undefined) updateData.subjectId = dto.subjectId;
    if (dto.classId !== undefined) updateData.classId = dto.classId;

    return this.prisma.assignment.update({
      where: { id },
      data: updateData,
      include: {
        teacher: { select: { id: true, name: true } },
        subject: { select: { id: true, name: true } },
        class: { select: { id: true, name: true } },
      },
    });
  }

  async deleteAssignment(id: string, teacherId: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id },
      select: { id: true, teacherId: true },
    });

    if (!assignment) throw new NotFoundException('Assignment not found');
    if (assignment.teacherId !== teacherId) {
      throw new ForbiddenException('You can only delete your own assignments');
    }

    return this.prisma.assignment.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async submitAssignment(assignmentId: string, studentId: string, dto: SubmitAssignmentDto) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment || !assignment.isActive) {
      throw new NotFoundException('Assignment not found');
    }

    const student = await this.prisma.user.findUnique({
      where: { id: studentId },
      select: { classId: true },
    });

    if (!student || student.classId !== assignment.classId) {
      throw new ForbiddenException('You are not in the class for this assignment');
    }

    const existing = await this.prisma.submission.findUnique({
      where: { assignmentId_studentId: { assignmentId, studentId } },
    });

    if (existing) {
      throw new BadRequestException('You have already submitted this assignment');
    }

    const isLate = new Date() > new Date(assignment.deadline);

    return this.prisma.submission.create({
      data: {
        assignmentId,
        studentId,
        content: dto.content || null,
        attachment: dto.attachment || null,
        isLate,
      },
      include: {
        assignment: {
          select: { id: true, title: true, deadline: true },
        },
      },
    });
  }

  async getSubmissions(assignmentId: string, teacherId: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      select: { id: true, teacherId: true },
    });

    if (!assignment) throw new NotFoundException('Assignment not found');
    if (assignment.teacherId !== teacherId) {
      throw new ForbiddenException('You can only view submissions for your own assignments');
    }

    return this.prisma.submission.findMany({
      where: { assignmentId },
      include: {
        student: {
          select: { id: true, nis: true, name: true, photo: true },
        },
      },
      orderBy: { submittedAt: 'desc' },
    });
  }

  async gradeSubmission(submissionId: string, teacherId: string, dto: GradeSubmissionDto) {
    const submission = await this.prisma.submission.findUnique({
      where: { id: submissionId },
      include: {
        assignment: { select: { id: true, teacherId: true, maxScore: true } },
      },
    });

    if (!submission) throw new NotFoundException('Submission not found');
    if (submission.assignment.teacherId !== teacherId) {
      throw new ForbiddenException('You can only grade submissions for your own assignments');
    }

    if (dto.score > submission.assignment.maxScore) {
      throw new BadRequestException(
        `Score cannot exceed max score of ${submission.assignment.maxScore}`,
      );
    }

    return this.prisma.submission.update({
      where: { id: submissionId },
      data: {
        score: dto.score,
        feedback: dto.feedback,
        gradedAt: new Date(),
      },
      include: {
        student: { select: { id: true, nis: true, name: true } },
        assignment: { select: { id: true, title: true } },
      },
    });
  }

  async getMySubmissions(studentId: string) {
    return this.prisma.submission.findMany({
      where: { studentId },
      include: {
        assignment: {
          include: {
            subject: { select: { id: true, name: true } },
            teacher: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { submittedAt: 'desc' },
    });
  }

  async getAssignmentStats(assignmentId: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      select: { id: true, classId: true },
    });

    if (!assignment) throw new NotFoundException('Assignment not found');

    const totalStudents = await this.prisma.user.count({
      where: { classId: assignment.classId, role: Role.SISWA, isActive: true },
    });

    const submissions = await this.prisma.submission.findMany({
      where: { assignmentId },
      select: { id: true, score: true, isLate: true, gradedAt: true },
    });

    return {
      totalStudents,
      totalSubmissions: submissions.length,
      graded: submissions.filter((s) => s.gradedAt !== null).length,
      ungraded: submissions.filter((s) => s.gradedAt === null).length,
      late: submissions.filter((s) => s.isLate).length,
      onTime: submissions.filter((s) => !s.isLate).length,
      averageScore:
        submissions.filter((s) => s.score !== null).length > 0
          ? Math.round(
              submissions
                .filter((s) => s.score !== null)
                .reduce((sum, s) => sum + (s.score as number), 0) /
                submissions.filter((s) => s.score !== null).length,
            )
          : null,
    };
  }
}
