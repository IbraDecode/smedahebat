import { IsString, IsArray, IsEnum, ArrayNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Day } from '@prisma/client';

export class CreatePicketDto {
  @ApiProperty({ enum: Day })
  @IsEnum(Day)
  day!: Day;

  @ApiProperty()
  @IsString()
  classId!: string;

  @ApiProperty({ type: [String] })
  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  studentIds!: string[];
}
