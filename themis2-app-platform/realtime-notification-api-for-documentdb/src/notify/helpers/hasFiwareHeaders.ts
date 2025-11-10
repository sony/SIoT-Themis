import { BadRequestException } from '@nestjs/common'

export function hasFiwareHeaders(fiwareService: string, fiwareServicePath: string) {
  if (fiwareService === undefined || fiwareServicePath === undefined) {
    throw new BadRequestException('FiwareService and/or FiwareServicePath header is missing')
  }
}
