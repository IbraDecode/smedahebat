import { IsString, IsNumber, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class GenerateRaporDto {
  @ApiProperty()
  @IsString()
  classId!: string;

  @ApiProperty()
  @IsString()
  academicYearId!: string;

  @ApiProperty({ default: 1 })
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  semester!: number;
}
