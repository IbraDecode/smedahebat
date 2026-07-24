import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Day } from '@prisma/client';

export class QueryPicketDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  classId?: string;

  @ApiPropertyOptional({ enum: Day })
  @IsOptional()
  @IsEnum(Day)
  day?: Day;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  date?: string;
}
