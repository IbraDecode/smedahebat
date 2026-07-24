import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { SchoolService } from './school.service';
import { UpdateSchoolDto } from './dto/update-school.dto';
import { CreateAcademicYearDto } from './dto/create-academic-year.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('School')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('school')
export class SchoolController {
  constructor(private schoolService: SchoolService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get school profile' })
  async getProfile() {
    return this.schoolService.getProfile();
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update school profile' })
  async updateProfile(@Body() dto: UpdateSchoolDto) {
    return this.schoolService.updateProfile(dto);
  }

  @Get('academic-years')
  @ApiOperation({ summary: 'List all academic years' })
  async getAcademicYears() {
    return this.schoolService.getAcademicYears();
  }

  @Post('academic-years')
  @ApiOperation({ summary: 'Create academic year' })
  async createAcademicYear(@Body() dto: CreateAcademicYearDto) {
    return this.schoolService.createAcademicYear(dto);
  }

  @Patch('academic-years/:id/activate')
  @ApiOperation({ summary: 'Set academic year as active' })
  async setActive(@Param('id') id: string) {
    return this.schoolService.setActiveAcademicYear(id);
  }

  @Delete('academic-years/:id')
  @ApiOperation({ summary: 'Delete academic year' })
  async deleteAcademicYear(@Param('id') id: string) {
    return this.schoolService.deleteAcademicYear(id);
  }
}
