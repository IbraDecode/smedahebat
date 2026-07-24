import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class DashboardStats {
  @ApiPropertyOptional()
  totalSubjects?: number;

  @ApiPropertyOptional()
  todayTasks?: number;

  @ApiPropertyOptional()
  monthlyAttendance?: number;

  @ApiPropertyOptional()
  newAnnouncements?: number;

  @ApiPropertyOptional()
  totalClasses?: number;

  @ApiPropertyOptional()
  todayAttendance?: number;

  @ApiPropertyOptional()
  pendingGrading?: number;

  @ApiPropertyOptional()
  totalStudents?: number;

  @ApiPropertyOptional()
  totalTeachers?: number;
}

class ScheduleItem {
  @ApiProperty()
  subjectName!: string;

  @ApiProperty()
  startTime!: string;

  @ApiProperty()
  endTime!: string;

  @ApiPropertyOptional()
  room?: string;
}

class Announcement {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  content!: string;

  @ApiProperty()
  createdAt!: Date;
}

class UpcomingTask {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  title!: string;

  @ApiProperty()
  subject!: string;

  @ApiProperty()
  dueDate!: Date;
}

class AttendanceToday {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  present!: number;

  @ApiProperty()
  absent!: number;

  @ApiProperty()
  permission!: number;
}

export class DashboardResponseDto {
  @ApiProperty()
  greeting!: string;

  @ApiProperty()
  stats!: DashboardStats;

  @ApiPropertyOptional({ type: [ScheduleItem] })
  todaySchedule?: ScheduleItem[];

  @ApiProperty({ type: [Announcement] })
  recentAnnouncements!: Announcement[];

  @ApiProperty({ type: [UpcomingTask] })
  upcomingTasks!: UpcomingTask[];

  @ApiPropertyOptional()
  attendanceToday?: AttendanceToday;
}
