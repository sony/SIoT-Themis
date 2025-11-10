import { Controller } from '@nestjs/common'

import { RefreshService } from './refresh.service'

@Controller('refresh')
export class RefreshController {
  constructor(private readonly refreshService: RefreshService) {}
}
