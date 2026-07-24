import { IsString, IsEmail, IsOptional, IsEnum, MinLength, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: '12345' })
  @IsString()
  @MinLength(4)
  nis!: string;

  @ApiProperty({ example: 'Budi Santoso' })
  @IsString()
  @MinLength(3)
  name!: string;

  @ApiPropertyOptional({ example: 'budi@school.com' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: '2006-01-15' })
  @IsDateString()
  birthDate!: string;

  @ApiProperty({ enum: Role, default: Role.SISWA })
  @IsEnum(Role)
  @IsOptional()
  role?: Role;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '12345' })
  @IsString()
  nis!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @MinLength(6)
  otp!: string;
}

export class SetPasswordDto {
  @ApiProperty({ example: '12345' })
  @IsString()
  nis!: string;

  @ApiProperty({ example: 'StrongP@ss123' })
  @IsString()
  @MinLength(8)
  password!: string;
}
