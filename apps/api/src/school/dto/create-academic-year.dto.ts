import {
  IsString,
  IsInt,
  IsBoolean,
  IsDateString,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateAcademicYearDto {
  @ApiProperty({ example: '2025/2026' })
  @IsString()
  year!: string;

  @ApiProperty({ default: 1 })
  @IsInt()
  @Min(1)
  @Max(2)
  semester!: number;

  @ApiProperty({ default: false })
  @IsBoolean()
  isActive!: boolean;

  @ApiProperty({ example: '2025-07-01' })
  @IsDateString()
  startDate!: string;

  @ApiProperty({ example: '2026-06-30' })
  @IsDateString()
  endDate!: string;
}
