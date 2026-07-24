import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { ClassesService } from './classes.service';
import { CreateGradeDto } from './dto/create-grade.dto';
import { UpdateGradeDto } from './dto/update-grade.dto';
import { CreateClassDto } from './dto/create-class.dto';
import { UpdateClassDto } from './dto/update-class.dto';
import { QueryClassDto } from './dto/query-class.dto';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { Roles } from '../../auth/decorators/roles.decorator';

@ApiTags('Academic - Classes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class ClassesController {
  constructor(private classesService: ClassesService) {}

  // ── Grades ──────────────────────────────────────────

  @Get('academic/grades')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH)
  @ApiOperation({ summary: 'List all grades' })
  async findAllGrades(@Query('schoolId') schoolId?: string) {
    return this.classesService.findAllGrades(schoolId);
  }

  @Post('academic/grades')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Create a new grade' })
  async createGrade(@Body() dto: CreateGradeDto) {
    return this.classesService.createGrade(dto);
  }

  @Get('academic/grades/:id')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH)
  @ApiOperation({ summary: 'Get grade by ID' })
  async findGradeById(@Param('id') id: string) {
    return this.classesService.findGradeById(id);
  }

  @Patch('academic/grades/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Update a grade' })
  async updateGrade(@Param('id') id: string, @Body() dto: UpdateGradeDto) {
    return this.classesService.updateGrade(id, dto);
  }

  @Delete('academic/grades/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Delete a grade' })
  async deleteGrade(@Param('id') id: string) {
    return this.classesService.deleteGrade(id);
  }

  // ── Classes ─────────────────────────────────────────

  @Get('academic/classes')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'List all classes' })
  async findAllClasses(@Query() query: QueryClassDto) {
    return this.classesService.findAllClasses(query);
  }

  @Post('academic/classes')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Create a new class' })
  async createClass(@Body() dto: CreateClassDto) {
    return this.classesService.createClass(dto);
  }

  @Get('academic/classes/:id')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'Get class by ID' })
  async findClassById(@Param('id') id: string) {
    return this.classesService.findClassById(id);
  }

  @Patch('academic/classes/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Update a class' })
  async updateClass(@Param('id') id: string, @Body() dto: UpdateClassDto) {
    return this.classesService.updateClass(id, dto);
  }

  @Delete('academic/classes/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Delete a class' })
  async deleteClass(@Param('id') id: string) {
    return this.classesService.deleteClass(id);
  }
}
