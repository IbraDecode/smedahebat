import { IsNumber, IsString, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GradeSubmissionDto {
  @ApiProperty()
  @IsNumber()
  @Min(0)
  score!: number;

  @ApiProperty()
  @IsString()
  feedback!: string;
}
