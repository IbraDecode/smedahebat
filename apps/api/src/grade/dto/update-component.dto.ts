import { IsString, IsOptional, IsNumber, IsIn, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateComponentDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ enum: ['tugas', 'uts', 'uas', 'praktik'] })
  @IsOptional()
  @IsString()
  @IsIn(['tugas', 'uts', 'uas', 'praktik'])
  type?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxScore?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;
}
