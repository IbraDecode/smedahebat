import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AttendanceService } from './attendance.service';
import { GenerateQrDto } from './dto/generate-qr.dto';
import { ScanQrDto } from './dto/scan-qr.dto';
import { QueryAttendanceDto } from './dto/query-attendance.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Attendance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('api/v1/attendance')
export class AttendanceController {
  constructor(private attendanceService: AttendanceService) {}

  @Post('generate')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Generate QR code for attendance session' })
  async generateQr(@CurrentUser('id') userId: string, @Body() dto: GenerateQrDto) {
    return this.attendanceService.generateQr(userId, dto);
  }

  @Post('scan')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Scan QR code and record attendance' })
  async scanQr(@CurrentUser('id') userId: string, @Body() dto: ScanQrDto) {
    return this.attendanceService.validateAndRecord(userId, dto);
  }

  @Get('session/:token')
  @ApiOperation({ summary: 'Check QR session status' })
  async getSessionStatus(@Param('token') token: string) {
    return this.attendanceService.getSessionStatus(token);
  }

  @Post('session/:id/deactivate')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Deactivate an active QR session' })
  async deactivateSession(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.attendanceService.deactivateSession(userId, id);
  }

  @Get('active-session')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Get currently active QR session for teacher' })
  async getActiveSession(@CurrentUser('id') userId: string) {
    return this.attendanceService.getActiveSession(userId);
  }

  @Get('class/:classId')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH)
  @ApiOperation({ summary: 'Get attendance records for a class' })
  async getAttendanceByClass(
    @Param('classId') classId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getAttendanceByClass(classId, query);
  }

  @Get('my')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get current student attendance history' })
  async getMyAttendance(
    @CurrentUser('id') userId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getAttendanceByStudent(userId, query);
  }

  @Get('recap/:classId')
  @Roles(Role.GURU, Role.WALI_KELAS, Role.ADMIN, Role.TU, Role.KEPALA_SEKOLAH)
  @ApiOperation({ summary: 'Get attendance recap for a class (daily summary)' })
  async getAttendanceRecap(
    @Param('classId') classId: string,
    @Query('date') date?: string,
  ) {
    return this.attendanceService.getAttendanceRecap(classId, date);
  }
}
