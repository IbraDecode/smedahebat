import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Day } from '@prisma/client';

export class UpdateScheduleDto {
  @ApiPropertyOptional({ enum: Day })
  @IsEnum(Day)
  @IsOptional()
  day?: Day;

  @ApiPropertyOptional({ example: '07:30' })
  @IsString()
  @IsOptional()
  startTime?: string;

  @ApiPropertyOptional({ example: '08:15' })
  @IsString()
  @IsOptional()
  endTime?: string;

  @ApiPropertyOptional({ example: 'Ruang 101' })
  @IsString()
  @IsOptional()
  room?: string;
}
