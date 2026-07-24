import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { parse } from 'csv-parse/sync';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUserDto } from './dto/query-user.dto';
import { AssignRoleDto } from './dto/assign-role.dto';
import { Role } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: QueryUserDto) {
    const { search, role, schoolId, academicYearId, page = 1, limit = 10 } = query;

    const where: any = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { nis: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (role) where.role = role;
    if (schoolId) where.schoolId = schoolId;
    if (academicYearId) where.academicYearId = academicYearId;

    const skip = (page - 1) * limit;

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          nis: true,
          nip: true,
          name: true,
          email: true,
          role: true,
          gender: true,
          phone: true,
          address: true,
          photo: true,
          birthDate: true,
          birthPlace: true,
          isActive: true,
          isFirstLogin: true,
          lastLogin: true,
          schoolId: true,
          academicYearId: true,
          createdAt: true,
          updatedAt: true,
          school: {
            select: { id: true, name: true },
          },
          academicYear: {
            select: { id: true, year: true, semester: true },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data,
      meta: { page, limit, total },
    };
  }

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        nis: true,
        nip: true,
        name: true,
        email: true,
        role: true,
        gender: true,
        phone: true,
        address: true,
        photo: true,
        birthDate: true,
        birthPlace: true,
        isActive: true,
        isFirstLogin: true,
        lastLogin: true,
        schoolId: true,
        academicYearId: true,
        createdAt: true,
        updatedAt: true,
        school: {
          select: { id: true, name: true },
        },
        academicYear: {
          select: { id: true, year: true, semester: true },
        },
      },
    });

    if (!user) throw new NotFoundException('User not found');

    return user;
  }

  async create(dto: CreateUserDto) {
    const existingNis = await this.prisma.user.findUnique({
      where: { nis: dto.nis },
    });
    if (existingNis) throw new ConflictException('NIS already exists');

    if (dto.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (existingEmail) throw new ConflictException('Email already exists');
    }

    if (dto.nip) {
      const existingNip = await this.prisma.user.findUnique({
        where: { nip: dto.nip },
      });
      if (existingNip) throw new ConflictException('NIP already exists');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 12);

    if (dto.schoolId) {
      const school = await this.prisma.school.findUnique({
        where: { id: dto.schoolId },
      });
      if (!school) throw new BadRequestException('School not found');
    }

    if (dto.academicYearId) {
      const academicYear = await this.prisma.academicYear.findUnique({
        where: { id: dto.academicYearId },
      });
      if (!academicYear) throw new BadRequestException('Academic year not found');
    }

    const user = await this.prisma.user.create({
      data: {
        nis: dto.nis,
        nip: dto.nip,
        name: dto.name,
        email: dto.email,
        password: hashedPassword,
        role: dto.role,
        gender: dto.gender,
        phone: dto.phone,
        address: dto.address,
        photo: dto.photo,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
        birthPlace: dto.birthPlace,
        isActive: dto.isActive ?? true,
        schoolId: dto.schoolId,
        academicYearId: dto.academicYearId,
      },
      select: {
        id: true,
        nis: true,
        nip: true,
        name: true,
        email: true,
        role: true,
        gender: true,
        phone: true,
        address: true,
        photo: true,
        birthDate: true,
        birthPlace: true,
        isActive: true,
        schoolId: true,
        academicYearId: true,
        createdAt: true,
      },
    });

    return user;
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findById(id);

    if (dto.nis) {
      const existing = await this.prisma.user.findFirst({
        where: { nis: dto.nis, id: { not: id } },
      });
      if (existing) throw new ConflictException('NIS already in use');
    }

    if (dto.email) {
      const existing = await this.prisma.user.findFirst({
        where: { email: dto.email, id: { not: id } },
      });
      if (existing) throw new ConflictException('Email already in use');
    }

    if (dto.nip) {
      const existing = await this.prisma.user.findFirst({
        where: { nip: dto.nip, id: { not: id } },
      });
      if (existing) throw new ConflictException('NIP already in use');
    }

    if (dto.schoolId) {
      const school = await this.prisma.school.findUnique({
        where: { id: dto.schoolId },
      });
      if (!school) throw new BadRequestException('School not found');
    }

    if (dto.academicYearId) {
      const academicYear = await this.prisma.academicYear.findUnique({
        where: { id: dto.academicYearId },
      });
      if (!academicYear) throw new BadRequestException('Academic year not found');
    }

    const data: any = { ...dto };

    if (dto.password) {
      data.password = await bcrypt.hash(dto.password, 12);
    }

    if (dto.birthDate) {
      data.birthDate = new Date(dto.birthDate);
    }

    const user = await this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        nis: true,
        nip: true,
        name: true,
        email: true,
        role: true,
        gender: true,
        phone: true,
        address: true,
        photo: true,
        birthDate: true,
        birthPlace: true,
        isActive: true,
        isFirstLogin: true,
        schoolId: true,
        academicYearId: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return user;
  }

  async delete(id: string) {
    await this.findById(id);

    const user = await this.prisma.user.update({
      where: { id },
      data: { isActive: false },
      select: {
        id: true,
        nis: true,
        name: true,
        isActive: true,
      },
    });

    return { message: 'User deactivated successfully', user };
  }

  async importCsv(file: { buffer: Buffer; originalname: string; mimetype: string; size: number }) {
    if (!file) throw new BadRequestException('CSV file is required');

    const records: any[] = parse(file.buffer.toString(), {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    if (records.length === 0) {
      throw new BadRequestException('CSV file is empty');
    }

    const results = {
      total: records.length,
      created: 0,
      skipped: 0,
      errors: [] as { row: number; message: string }[],
    };

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      try {
        if (!row.nis || !row.name || !row.password) {
          results.errors.push({
            row: i + 1,
            message: 'Missing required fields (nis, name, password)',
          });
          results.skipped++;
          continue;
        }

        const existing = await this.prisma.user.findUnique({
          where: { nis: row.nis },
        });
        if (existing) {
          results.errors.push({
            row: i + 1,
            message: `NIS ${row.nis} already exists`,
          });
          results.skipped++;
          continue;
        }

        const validRoles = Object.values(Role);
        const role = validRoles.includes(row.role as Role)
          ? (row.role as Role)
          : Role.SISWA;

        const hashedPassword = await bcrypt.hash(row.password, 12);

        await this.prisma.user.create({
          data: {
            nis: row.nis,
            nip: row.nip || undefined,
            name: row.name,
            email: row.email || undefined,
            password: hashedPassword,
            role,
            phone: row.phone || undefined,
            address: row.address || undefined,
            isActive: true,
          },
        });

        results.created++;
      } catch (error: any) {
        results.errors.push({
          row: i + 1,
          message: error.message || 'Unknown error',
        });
        results.skipped++;
      }
    }

    return results;
  }

  async assignRole(id: string, dto: AssignRoleDto) {
    await this.findById(id);

    const user = await this.prisma.user.update({
      where: { id },
      data: { role: dto.role },
      select: {
        id: true,
        nis: true,
        name: true,
        role: true,
      },
    });

    return user;
  }
}
