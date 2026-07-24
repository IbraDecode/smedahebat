import { Module } from '@nestjs/common';
import { PicketService } from './picket.service';
import { PicketController } from './picket.controller';

@Module({
  controllers: [PicketController],
  providers: [PicketService],
  exports: [PicketService],
})
export class PicketModule {}
