import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common'

import { hasFiwareHeaders } from './helpers/hasFiwareHeaders'

@Injectable()
export class NotifyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest()
    const fiwareService = request.headers['fiware-service']
    const fiwareServicePath = request.headers['fiware-servicepath']

    hasFiwareHeaders(fiwareService, fiwareServicePath)

    return true
  }
}
