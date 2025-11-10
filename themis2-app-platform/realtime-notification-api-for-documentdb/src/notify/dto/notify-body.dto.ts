import { IsString, IsNotEmpty, IsOptional, IsObject, IsUrl } from 'class-validator'

export class NotifyBodyDto {
  @IsString()
  @IsNotEmpty()
  type: string

  // eslint-disable-next-line @typescript-eslint/naming-convention
  @IsUrl({ require_tld: false })
  @IsNotEmpty()
  url: string

  @IsObject()
  @IsOptional()
  condition?: {
    expression?: {
      georel?: string
      geometry?: string
      coords?: string
      q?: string
    }
    attrs?: string[]
  }
}

export class NotifyPatchBodyDto {
  @IsString()
  @IsOptional()
  type: string

  // eslint-disable-next-line @typescript-eslint/naming-convention
  @IsUrl({ require_tld: false })
  @IsOptional()
  url: string

  @IsObject()
  @IsOptional()
  condition?: {
    expression?: {
      georel?: string
      geometry?: string
      coords?: string
      q?: string
    }
    attrs?: string[]
  }
}
