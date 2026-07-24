import { Module } from '@nestjs/common';
import { ClassesService } from './classes/classes.service';
import { ClassesController } from './classes/classes.controller';
import { SubjectsService } from './subjects/subjects.service';
import { SubjectsController } from './subjects/subjects.controller';
import { ScheduleService } from './schedule/schedule.service';
import { ScheduleController } from './schedule/schedule.controller';

@Module({
  controllers: [ClassesController, SubjectsController, ScheduleController],
  providers: [ClassesService, SubjectsService, ScheduleService],
  exports: [ClassesService, SubjectsService, ScheduleService],
})
export class AcademicModule {}
