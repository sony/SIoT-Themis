import { Module } from '@nestjs/common'

import { RefreshModule } from '../refresh/refresh.module'

import { SchedulerController } from './scheduler.controller'
import { SchedulerService } from './scheduler.service'

@Module({
  imports: [RefreshModule],
  controllers: [SchedulerController],
  providers: [SchedulerService],
  exports: [SchedulerService],
})
export class SchedulerModule {}
