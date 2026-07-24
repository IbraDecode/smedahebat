import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateGradeDto } from './dto/create-grade.dto';
import { UpdateGradeDto } from './dto/update-grade.dto';
import { CreateClassDto } from './dto/create-class.dto';
import { UpdateClassDto } from './dto/update-class.dto';
import { QueryClassDto } from './dto/query-class.dto';

@Injectable()
export class ClassesService {
  constructor(private prisma: PrismaService) {}

  // ── Grades ──────────────────────────────────────────

  async createGrade(dto: CreateGradeDto) {
    const existing = await this.prisma.grade.findUnique({
      where: { schoolId_name: { schoolId: dto.schoolId, name: dto.name } },
    });
    if (existing) throw new ConflictException('Grade already exists');

    return this.prisma.grade.create({ data: dto });
  }

  async findAllGrades(schoolId?: string) {
    const where: any = {};
    if (schoolId) where.schoolId = schoolId;
    return this.prisma.grade.findMany({
      where,
      include: { _count: { select: { classes: true } } },
      orderBy: { name: 'asc' },
    });
  }

  async findGradeById(id: string) {
    const grade = await this.prisma.grade.findUnique({
      where: { id },
      include: { classes: true },
    });
    if (!grade) throw new NotFoundException('Grade not found');
    return grade;
  }

  async updateGrade(id: string, dto: UpdateGradeDto) {
    await this.findGradeById(id);
    return this.prisma.grade.update({ where: { id }, data: dto });
  }

  async deleteGrade(id: string) {
    await this.findGradeById(id);
    await this.prisma.grade.delete({ where: { id } });
    return { message: 'Grade deleted successfully' };
  }

  // ── Classes ─────────────────────────────────────────

  async createClass(dto: CreateClassDto) {
    const existing = await this.prisma.class.findUnique({
      where: { schoolId_name: { schoolId: dto.schoolId, name: dto.name } },
    });
    if (existing) throw new ConflictException('Class already exists');

    return this.prisma.class.create({
      data: dto,
      include: { grade: true },
    });
  }

  async findAllClasses(query: QueryClassDto) {
    const { gradeId, search, schoolId } = query;
    const where: any = {};

    if (gradeId) where.gradeId = gradeId;
    if (schoolId) where.schoolId = schoolId;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.class.findMany({
      where,
      include: {
        grade: true,
        _count: { select: { users: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  async findClassById(id: string) {
    const cls = await this.prisma.class.findUnique({
      where: { id },
      include: {
        grade: true,
        _count: { select: { users: true } },
      },
    });
    if (!cls) throw new NotFoundException('Class not found');
    return cls;
  }

  async updateClass(id: string, dto: UpdateClassDto) {
    await this.findClassById(id);
    return this.prisma.class.update({
      where: { id },
      data: dto,
      include: { grade: true },
    });
  }

  async deleteClass(id: string) {
    await this.findClassById(id);
    await this.prisma.class.delete({ where: { id } });
    return { message: 'Class deleted successfully' };
  }
}
