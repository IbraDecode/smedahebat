import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SchoolModule } from './school/school.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { AcademicModule } from './academic/academic.module';
import { AttendanceModule } from './attendance/attendance.module';
import { NotificationModule } from './notification/notification.module';
import { AssignmentModule } from './assignment/assignment.module';
import { GradeModule } from './grade/grade.module';
import { PicketModule } from './picket/picket.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    EventEmitterModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    SchoolModule,
    DashboardModule,
    AcademicModule,
    AttendanceModule,
    NotificationModule,
    AssignmentModule,
    GradeModule,
    PicketModule,
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
      exclude: ['/api/*'],
    }),
  ],
})
export class AppModule {}
