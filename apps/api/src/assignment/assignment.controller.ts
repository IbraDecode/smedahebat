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
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import * as crypto from 'crypto';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiConsumes } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AssignmentService } from './assignment.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { UpdateAssignmentDto } from './dto/update-assignment.dto';
import { SubmitAssignmentDto } from './dto/submit-assignment.dto';
import { GradeSubmissionDto } from './dto/grade-submission.dto';
import { QueryAssignmentDto } from './dto/query-assignment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

const fileStorage = diskStorage({
  destination: join(process.cwd(), 'uploads', 'assignments'),
  filename: (_req, file, cb) => {
    const ext = extname(file.originalname);
    cb(null, `${crypto.randomUUID()}${ext}`);
  },
});

@ApiTags('Assignments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('api/v1')
export class AssignmentController {
  constructor(private assignmentService: AssignmentService) {}

  @Post('assignments')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'Create a new assignment (GURU)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('attachment', {
      storage: fileStorage,
      limits: { fileSize: 10 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        if (!file.originalname.match(/\.(pdf|doc|docx|zip|rar|jpg|jpeg|png|ppt|pptx|xls|xlsx)$/i)) {
          cb(new BadRequestException('Only document and image files are allowed'), false);
          return;
        }
        cb(null, true);
      },
    }),
  )
  async createAssignment(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateAssignmentDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file) {
      dto.attachment = `/uploads/assignments/${file.filename}`;
    }
    return this.assignmentService.createAssignment(userId, dto);
  }

  @Get('assignments')
  @ApiOperation({ summary: 'List assignments (role-based filtering)' })
  async getAssignments(
    @CurrentUser() user: any,
    @Query() query: QueryAssignmentDto,
  ) {
    return this.assignmentService.getAssignments(user.id, user.role, query);
  }

  @Get('assignments/:id')
  @ApiOperation({ summary: 'Get assignment detail' })
  async getAssignmentById(
    @Param('id') id: string,
    @CurrentUser() user: any,
  ) {
    return this.assignmentService.getAssignmentById(id, user.id, user.role);
  }

  @Patch('assignments/:id')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'Update assignment (author only)' })
  async updateAssignment(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateAssignmentDto,
  ) {
    return this.assignmentService.updateAssignment(id, userId, dto);
  }

  @Delete('assignments/:id')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'Soft delete assignment (author only)' })
  async deleteAssignment(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.assignmentService.deleteAssignment(id, userId);
  }

  @Post('assignments/:id/submit')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Submit assignment (SISWA)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('attachment', {
      storage: fileStorage,
      limits: { fileSize: 10 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        if (!file.originalname.match(/\.(pdf|doc|docx|zip|rar|jpg|jpeg|png|ppt|pptx|xls|xlsx)$/i)) {
          cb(new BadRequestException('Only document and image files are allowed'), false);
          return;
        }
        cb(null, true);
      },
    }),
  )
  async submitAssignment(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: SubmitAssignmentDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file) {
      dto.attachment = `/uploads/assignments/${file.filename}`;
    }
    return this.assignmentService.submitAssignment(id, userId, dto);
  }

  @Get('assignments/:id/submissions')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'List submissions for grading (GURU)' })
  async getSubmissions(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.assignmentService.getSubmissions(id, userId);
  }

  @Patch('submissions/:id/grade')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'Grade a submission (GURU)' })
  async gradeSubmission(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: GradeSubmissionDto,
  ) {
    return this.assignmentService.gradeSubmission(id, userId, dto);
  }

  @Get('submissions/my')
  @Roles(Role.SISWA)
  @ApiOperation({ summary: 'Get my submissions (SISWA)' })
  async getMySubmissions(@CurrentUser('id') userId: string) {
    return this.assignmentService.getMySubmissions(userId);
  }

  @Get('assignments/:id/stats')
  @Roles(Role.GURU, Role.ADMIN)
  @ApiOperation({ summary: 'Get assignment submission stats' })
  async getAssignmentStats(@Param('id') id: string) {
    return this.assignmentService.getAssignmentStats(id);
  }
}
