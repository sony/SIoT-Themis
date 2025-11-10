import { Type } from 'class-transformer'
import { IsString, IsNotEmpty, IsOptional, IsInt } from 'class-validator'

export class SearchQueryDto {
  @IsString()
  @IsNotEmpty()
  type: string

  @IsString()
  @IsOptional()
  q?: string

  @IsString()
  @IsOptional()
  geoattr?: string

  @IsString()
  @IsOptional()
  georel?: string

  @IsString()
  @IsOptional()
  geometry?: string

  @IsString()
  @IsOptional()
  coords?: string

  @IsOptional()
  @IsInt()
  @Type(() => Number)
  limit?: number
}
