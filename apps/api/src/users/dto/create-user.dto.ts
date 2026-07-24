import {
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  IsBoolean,
  IsDateString,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role, Gender } from '@prisma/client';

export class CreateUserDto {
  @ApiProperty({ example: '12345' })
  @IsString()
  nis!: string;

  @ApiPropertyOptional({ example: '196501011990011001' })
  @IsString()
  @IsOptional()
  nip?: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  @MinLength(2)
  name!: string;

  @ApiPropertyOptional({ example: 'john@school.sch.id' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: 'StrongP@ss123' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ enum: Role, example: Role.SISWA })
  @IsEnum(Role)
  role!: Role;

  @ApiPropertyOptional({ enum: Gender, example: Gender.L })
  @IsEnum(Gender)
  @IsOptional()
  gender?: Gender;

  @ApiPropertyOptional({ example: '08123456789' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ example: 'Jl. Contoh No. 1' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  photo?: string;

  @ApiPropertyOptional({ example: '2000-01-15' })
  @IsDateString()
  @IsOptional()
  birthDate?: string;

  @ApiPropertyOptional({ example: 'Mataram' })
  @IsString()
  @IsOptional()
  birthPlace?: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  schoolId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  academicYearId?: string;
}
