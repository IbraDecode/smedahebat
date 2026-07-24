import { IsString, IsOptional, IsNumber, IsIn, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateComponentDto {
  @ApiProperty()
  @IsString()
  name!: string;

  @ApiProperty({ enum: ['tugas', 'uts', 'uas', 'praktik'] })
  @IsString()
  @IsIn(['tugas', 'uts', 'uas', 'praktik'])
  type!: string;

  @ApiPropertyOptional({ default: 100 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @ApiPropertyOptional({ default: 100 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxScore?: number;

  @ApiProperty()
  @IsString()
  subjectId!: string;

  @ApiProperty()
  @IsString()
  classId!: string;

  @ApiProperty()
  @IsString()
  academicYearId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;
}
