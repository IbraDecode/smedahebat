import { IsString, IsOptional, IsNumber, Min, ValidateNested, IsArray } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class BulkScoreItem {
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

export class InputBulkScoresDto {
  @ApiProperty()
  @IsString()
  componentId!: string;

  @ApiProperty({ type: [BulkScoreItem] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BulkScoreItem)
  scores!: BulkScoreItem[];
}
