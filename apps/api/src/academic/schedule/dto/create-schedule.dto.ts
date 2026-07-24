import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Day } from '@prisma/client';

export class CreateScheduleDto {
  @ApiProperty()
  @IsString()
  teacherSubjectId!: string;

  @ApiProperty({ enum: Day })
  @IsEnum(Day)
  day!: Day;

  @ApiProperty({ example: '07:30' })
  @IsString()
  startTime!: string;

  @ApiProperty({ example: '08:15' })
  @IsString()
  endTime!: string;

  @ApiPropertyOptional({ example: 'Ruang 101' })
  @IsString()
  @IsOptional()
  room?: string;
}
