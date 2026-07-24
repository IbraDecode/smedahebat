import { Module } from '@nestjs/common';
import { ClassesService } from './classes/classes.service';
import { ClassesController } from './classes/classes.controller';
import { SubjectsService } from './subjects/subjects.service';
import { SubjectsController } from './subjects/subjects.controller';

@Module({
  controllers: [ClassesController, SubjectsController],
  providers: [ClassesService, SubjectsService],
  exports: [ClassesService, SubjectsService],
})
export class AcademicModule {}
