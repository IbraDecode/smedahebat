import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { AssignmentService } from './assignment.service';
import { AssignmentController } from './assignment.controller';

@Module({
  imports: [
    MulterModule.register({
      dest: './uploads/assignments',
    }),
  ],
  controllers: [AssignmentController],
  providers: [AssignmentService],
  exports: [AssignmentService],
})
export class AssignmentModule {}
