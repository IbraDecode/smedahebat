import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';
import { QuerySubjectDto } from './dto/query-subject.dto';

@Injectable()
export class SubjectsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateSubjectDto) {
    const existing = await this.prisma.subject.findUnique({
      where: { schoolId_name: { schoolId: dto.schoolId, name: dto.name } },
    });
    if (existing) throw new ConflictException('Subject already exists');

    return this.prisma.subject.create({ data: dto });
  }

  async findAll(query: QuerySubjectDto) {
    const { category, schoolId } = query;
    const where: any = {};

    if (category) where.category = category;
    if (schoolId) where.schoolId = schoolId;

    return this.prisma.subject.findMany({
      where,
      orderBy: { name: 'asc' },
    });
  }

  async findById(id: string) {
    const subject = await this.prisma.subject.findUnique({ where: { id } });
    if (!subject) throw new NotFoundException('Subject not found');
    return subject;
  }

  async update(id: string, dto: UpdateSubjectDto) {
    await this.findById(id);
    return this.prisma.subject.update({ where: { id }, data: dto });
  }

  async delete(id: string) {
    await this.findById(id);
    await this.prisma.subject.delete({ where: { id } });
    return { message: 'Subject deleted successfully' };
  }
}
