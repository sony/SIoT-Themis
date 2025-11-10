import { IsNotEmpty, IsString } from 'class-validator'

export class ParamDto {
  @IsString()
  @IsNotEmpty()
  token: string
}
