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
import { ApiBearerAuth, ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { Role, Day } from '@prisma/client';
import { ScheduleService } from './schedule.service';
import { CreateTeacherSubjectDto } from './dto/create-teacher-subject.dto';
import { QueryTeacherSubjectDto } from './dto/query-teacher-subject.dto';
import { CreateScheduleDto } from './dto/create-schedule.dto';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';

@ApiTags('Academic - Schedule')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class ScheduleController {
  constructor(private scheduleService: ScheduleService) {}

  @Post('academic/teacher-subjects')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Assign teacher to subject and class' })
  async assignTeacherSubject(@Body() dto: CreateTeacherSubjectDto) {
    return this.scheduleService.assignTeacherSubject(dto);
  }

  @Get('academic/teacher-subjects')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'List teacher-subject-class assignments' })
  async getTeacherSubjects(@Query() query: QueryTeacherSubjectDto) {
    return this.scheduleService.getTeacherSubjects(query);
  }

  @Delete('academic/teacher-subjects/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Remove teacher subject assignment' })
  async removeTeacherSubject(@Param('id') id: string) {
    return this.scheduleService.removeTeacherSubject(id);
  }

  @Post('academic/schedules')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Create a schedule entry' })
  async createSchedule(@Body() dto: CreateScheduleDto) {
    return this.scheduleService.createSchedule(dto);
  }

  @Get('academic/schedules/by-class/:classId')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS, Role.SISWA)
  @ApiOperation({ summary: 'Get schedule by class' })
  @ApiQuery({ name: 'day', enum: Day, required: false })
  async getScheduleByClass(
    @Param('classId') classId: string,
    @Query('day') day?: Day,
  ) {
    return this.scheduleService.getScheduleByClass(classId, day);
  }

  @Get('academic/schedules/by-teacher/:teacherId')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS)
  @ApiOperation({ summary: 'Get schedule by teacher' })
  @ApiQuery({ name: 'day', enum: Day, required: false })
  async getScheduleByTeacher(
    @Param('teacherId') teacherId: string,
    @Query('day') day?: Day,
  ) {
    return this.scheduleService.getScheduleByTeacher(teacherId, day);
  }

  @Get('academic/schedules/today')
  @Roles(Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH, Role.GURU, Role.WALI_KELAS, Role.SISWA)
  @ApiOperation({ summary: 'Get today schedule for current user' })
  async getTodaySchedule(@CurrentUser() user: any) {
    if (user.role === Role.SISWA) {
      return this.scheduleService.getTodayScheduleByClass(user.classId);
    }
    return this.scheduleService.getTodayScheduleByTeacher(user.id);
  }

  @Patch('academic/schedules/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Update a schedule entry' })
  async updateSchedule(
    @Param('id') id: string,
    @Body() dto: UpdateScheduleDto,
  ) {
    return this.scheduleService.updateSchedule(id, dto);
  }

  @Delete('academic/schedules/:id')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Delete a schedule entry' })
  async deleteSchedule(@Param('id') id: string) {
    return this.scheduleService.deleteSchedule(id);
  }
}
