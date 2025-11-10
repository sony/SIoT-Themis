import { Injectable, Logger } from '@nestjs/common'
import { Cron } from '@nestjs/schedule'

import { RefreshService } from '../refresh/refresh.service'

@Injectable()
export class SchedulerService {
  private readonly logger = new Logger(SchedulerService.name)

  constructor(private readonly refreshService: RefreshService) {}

  /**
   * Cron job runs every minute to check for servicer updates
   * Cron expression: '0 * * * * *' = runs at second 0 of every minute
   */
  @Cron('0 * * * * *')
  async handleServicerUpdateCheck() {
    this.logger.debug('Starting servicer update check...')

    try {
      await this.refreshService.checkForUpdates()
      this.logger.debug('Completed servicer update check')
    } catch (error) {
      this.logger.error('Error during servicer update check:', error.message)
    }
  }

  async manualCheck(): Promise<void> {
    this.logger.log('Performing manual servicer check...')
    await this.refreshService.checkForUpdates()
    this.logger.log('Completed manual servicer check')
  }
}
