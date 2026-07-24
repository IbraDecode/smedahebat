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
  NotFoundException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { GradeService } from './grade.service';
import { CreateComponentDto } from './dto/create-component.dto';
import { UpdateComponentDto } from './dto/update-component.dto';
import { InputScoreDto } from './dto/input-score.dto';
import { InputBulkScoresDto } from './dto/input-bulk-scores.dto';
import { QueryGradeDto } from './dto/query-grade.dto';
import { GenerateRaporDto } from './dto/generate-rapor.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Grade & Rapor')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('api/v1/grade')
export class GradeController {
  constructor(private gradeService: GradeService) {}

  // ── Components ────────────────────────────────────────

  @Post('components')
  @Roles(Role.GURU)
  @ApiOperation({ summary: 'Create a grade component (GURU)' })
  async createComponent(@Body() dto: CreateComponentDto) {
    return this.gradeService.createComponent(dto);
  }

  @Get('components')
  @ApiOperation({ summary: 'List grade components' })
  async getComponents(@Query() query: QueryGradeDto) {
    return this.gradeService.getComponents(query);
  }

  @Patch('components/:id')
  @Roles(Role.GURU)
  @ApiOperation({ summary: 'Update a grade component (GURU)' })
  async updateComponent(
    @Param('id') id: string,
    @Body() dto: UpdateComponentDto,
  ) {
    return this.gradeService.updateComponent(id, dto);
  }

  @Delete('components/:id')
  @Roles(Role.GURU)
  @ApiOperation({ summary: 'Delete a grade component (GURU)' })
  async deleteComponent(@Param('id') id: string) {
    return this.gradeService.deleteComponent(id);
  }

  // ── Scores ────────────────────────────────────────────

  @Post('scores')
  @Roles(Role.GURU)
  @ApiOperation({ summary: 'Input a single score (GURU)' })
  async inputScore(@Body() dto: InputScoreDto) {
    return this.gradeService.inputScore(dto);
  }

  @Post('scores/bulk')
  @Roles(Role.GURU)
  @ApiOperation({ summary: 'Bulk input scores (GURU)' })
  async inputBulkScores(@Body() dto: InputBulkScoresDto) {
    return this.gradeService.inputBulkScores(dto);
  }

  @Get('scores/component/:componentId')
  @Roles(Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'Get scores by component (GURU/WALI)' })
  async getScoresByComponent(@Param('componentId') componentId: string) {
    return this.gradeService.getScoresByComponent(componentId);
  }

  @Get('scores/my')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get my scores (SISWA)' })
  async getMyScores(
    @CurrentUser('id') userId: string,
    @Query() query: QueryGradeDto,
  ) {
    return this.gradeService.getScoresByStudent(userId, query);
  }

  @Get('scores/student/:studentId')
  @Roles(Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'Get student scores (GURU/WALI)' })
  async getStudentScores(
    @Param('studentId') studentId: string,
    @Query() query: QueryGradeDto,
  ) {
    return this.gradeService.getScoresByStudent(studentId, query);
  }

  @Get('scores/student/:studentId/subject/:subjectId')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.SISWA)
  @ApiOperation({ summary: 'Detailed scores per component type' })
  async getStudentSubjectScores(
    @Param('studentId') studentId: string,
    @Param('subjectId') subjectId: string,
  ) {
    return this.gradeService.getStudentSubjectScores(studentId, subjectId);
  }

  // ── Rapor ─────────────────────────────────────────────

  @Post('rapor/generate')
  @Roles(Role.WALI_KELAS)
  @ApiOperation({ summary: 'Generate report cards for a class (WALI_KELAS)' })
  async generateRapor(@Body() dto: GenerateRaporDto) {
    return this.gradeService.generateReportCard(dto);
  }

  @Get('rapor/my')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get my report card (SISWA)' })
  async getMyRapor(
    @CurrentUser() user: any,
    @Query('academicYearId') academicYearId: string,
    @Query('semester') semester: string,
  ) {
    return this.gradeService.getReportCard(
      user.id,
      academicYearId,
      parseInt(semester) || 1,
      user.classId,
    );
  }

  @Get('rapor/:id')
  @ApiOperation({ summary: 'Get report card detail' })
  async getRaporById(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    const rc = await this.gradeService.getRaporById(id);
    const isOwner = rc.studentId === user.id;
    const isAuthorized =
      user.role === Role.WALI_KELAS || user.role === Role.GURU || user.role === Role.ADMIN;
    if (!isOwner && !isAuthorized) {
      throw new NotFoundException('Report card not found');
    }
    return rc;
  }

  @Patch('rapor/:id/publish')
  @Roles(Role.WALI_KELAS)
  @ApiOperation({ summary: 'Publish a report card (WALI_KELAS)' })
  async publishRapor(@Param('id') id: string) {
    return this.gradeService.publishReportCard(id);
  }

  @Get('rapor/class/:classId')
  @Roles(Role.WALI_KELAS)
  @ApiOperation({ summary: 'Get all report cards for a class (WALI_KELAS)' })
  async getClassRapor(
    @Param('classId') classId: string,
    @Query('academicYearId') academicYearId: string,
    @Query('semester') semester: string,
  ) {
    return this.gradeService.getClassReportCards(
      classId,
      academicYearId,
      parseInt(semester) || 1,
    );
  }
}
