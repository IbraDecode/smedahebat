import { IsString, IsOptional, IsNumber, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class InputScoreDto {
  @ApiProperty()
  @IsString()
  componentId!: string;

  @ApiProperty()
  @IsString()
  studentId!: string;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  score!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
