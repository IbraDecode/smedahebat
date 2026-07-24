import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class QueryTeacherSubjectDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  teacherId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  classId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  subjectId?: string;
}
