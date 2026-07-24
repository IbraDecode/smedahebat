import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSchoolDto } from './dto/update-school.dto';
import { CreateAcademicYearDto } from './dto/create-academic-year.dto';

@Injectable()
export class SchoolService {
  constructor(private prisma: PrismaService) {}

  async getProfile() {
    const school = await this.prisma.school.findFirst({
      include: {
        academicYears: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!school) throw new NotFoundException('School profile not found');

    return school;
  }

  async updateProfile(dto: UpdateSchoolDto) {
    let school = await this.prisma.school.findFirst();

    if (!school) {
      school = await this.prisma.school.create({
        data: {
          name: dto.name || 'SMKN 2 Mataram',
          ...dto,
        },
      });
      return school;
    }

    const updated = await this.prisma.school.update({
      where: { id: school.id },
      data: dto,
    });

    return updated;
  }

  async getAcademicYears() {
    const school = await this.prisma.school.findFirst();
    if (!school) throw new NotFoundException('School not found');

    return this.prisma.academicYear.findMany({
      where: { schoolId: school.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createAcademicYear(dto: CreateAcademicYearDto) {
    const school = await this.prisma.school.findFirst();
    if (!school) throw new NotFoundException('School not found. Create school profile first.');

    const existing = await this.prisma.academicYear.findUnique({
      where: {
        schoolId_year_semester: {
          schoolId: school.id,
          year: dto.year,
          semester: dto.semester,
        },
      },
    });

    if (existing) throw new BadRequestException('Academic year already exists');

    if (dto.isActive) {
      await this.prisma.academicYear.updateMany({
        where: { schoolId: school.id, isActive: true },
        data: { isActive: false },
      });
    }

    const academicYear = await this.prisma.academicYear.create({
      data: {
        schoolId: school.id,
        year: dto.year,
        semester: dto.semester,
        isActive: dto.isActive,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
      },
    });

    return academicYear;
  }

  async setActiveAcademicYear(id: string) {
    const school = await this.prisma.school.findFirst();
    if (!school) throw new NotFoundException('School not found');

    const academicYear = await this.prisma.academicYear.findFirst({
      where: { id, schoolId: school.id },
    });

    if (!academicYear) throw new NotFoundException('Academic year not found');

    await this.prisma.academicYear.updateMany({
      where: { schoolId: school.id, isActive: true },
      data: { isActive: false },
    });

    const updated = await this.prisma.academicYear.update({
      where: { id },
      data: { isActive: true },
    });

    return updated;
  }

  async deleteAcademicYear(id: string) {
    const school = await this.prisma.school.findFirst();
    if (!school) throw new NotFoundException('School not found');

    const academicYear = await this.prisma.academicYear.findFirst({
      where: { id, schoolId: school.id },
    });

    if (!academicYear) throw new NotFoundException('Academic year not found');

    await this.prisma.academicYear.delete({ where: { id } });

    return { message: 'Academic year deleted successfully' };
  }
}
