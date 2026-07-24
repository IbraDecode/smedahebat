import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTeacherSubjectDto {
  @ApiProperty()
  @IsString()
  teacherId!: string;

  @ApiProperty()
  @IsString()
  subjectId!: string;

  @ApiProperty()
  @IsString()
  classId!: string;

  @ApiProperty()
  @IsString()
  schoolId!: string;
}
