import { Controller, Post, HttpCode, HttpStatus } from '@nestjs/common'

import { SchedulerService } from './scheduler.service'

@Controller('scheduler')
export class SchedulerController {
  constructor(private readonly schedulerService: SchedulerService) {}

  /**
   * Endpoint to trigger manual servicer check
   * POST /scheduler/check-servicers
   */
  @Post('check-servicers')
  @HttpCode(HttpStatus.OK)
  async manualCheck(): Promise<{ message: string }> {
    await this.schedulerService.manualCheck()
    return { message: 'Manual servicer check completed' }
  }
}
