import { IsString, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateGradeDto {
  @ApiPropertyOptional({ example: 'X' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: '10' })
  @IsString()
  @IsOptional()
  alias?: string;
}
