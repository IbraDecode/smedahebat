import { IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateSubjectDto {
  @ApiProperty()
  @IsString()
  schoolId!: string;

  @ApiProperty({ example: 'Matematika' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({ example: 'MTK' })
  @IsString()
  @IsOptional()
  code?: string;

  @ApiPropertyOptional({ example: 'Wajib' })
  @IsString()
  @IsOptional()
  category?: string;

  @ApiPropertyOptional({ default: true })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
