import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { PicketService } from './picket.service';
import { CreatePicketDto } from './dto/create-picket.dto';
import { ChecklistDto } from './dto/checklist.dto';
import { QueryPicketDto } from './dto/query-picket.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Picket')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('api/v1/picket')
export class PicketController {
  constructor(private picketService: PicketService) {}

  @Post()
  @Roles(Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Create or update picket (WALI_KELAS/ADMIN)' })
  async upsertPicket(@Body() dto: CreatePicketDto) {
    return this.picketService.upsertPicket(dto);
  }

  @Get('class/:classId')
  @ApiOperation({ summary: 'Get class picket schedule' })
  async getPicketsByClass(
    @Param('classId') classId: string,
    @Query() query: QueryPicketDto,
  ) {
    return this.picketService.getPicketsByClass(classId, query);
  }

  @Get('my')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get my picket schedule (SISWA)' })
  async getMyPicket(@CurrentUser('id') userId: string) {
    return this.picketService.getMyPicket(userId);
  }

  @Get('today/:classId')
  @ApiOperation({ summary: "Get today's picket for a class" })
  async getTodayPicket(@Param('classId') classId: string) {
    return this.picketService.getTodayPicket(classId);
  }

  @Post(':id/checklist')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Mark picket as done (SISWA)' })
  async checklist(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: ChecklistDto,
  ) {
    return this.picketService.checklist(id, userId, dto);
  }

  @Get('history')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get my picket history (SISWA)' })
  async getMyHistory(
    @CurrentUser('id') userId: string,
    @Query() query: QueryPicketDto,
  ) {
    return this.picketService.getHistory(userId, query);
  }

  @Get('history/:classId')
  @Roles(Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Get class picket history (WALI_KELAS)' })
  async getClassHistory(
    @Param('classId') classId: string,
    @Query() query: QueryPicketDto,
  ) {
    return this.picketService.getClassHistory(classId, query);
  }

  @Get('stats/:classId')
  @ApiOperation({ summary: 'Get picket stats for dashboard' })
  async getStats(@Param('classId') classId: string) {
    return this.picketService.getStats(classId);
  }

  @Delete(':id')
  @Roles(Role.WALI_KELAS, Role.ADMIN)
  @ApiOperation({ summary: 'Delete picket (WALI_KELAS/ADMIN)' })
  async deletePicket(@Param('id') id: string) {
    return this.picketService.deletePicket(id);
  }
}
