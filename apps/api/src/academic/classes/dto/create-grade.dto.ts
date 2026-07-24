import { IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateGradeDto {
  @ApiProperty({ example: 'X' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({ example: '10' })
  @IsString()
  @IsOptional()
  alias?: string;

  @ApiProperty()
  @IsString()
  schoolId!: string;
}
