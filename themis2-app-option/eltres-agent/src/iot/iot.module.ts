import { HttpModule } from '@nestjs/axios'
import { Module } from '@nestjs/common'
import { RedisService } from 'src/redis.service'

import { RefreshModule } from '../refresh/refresh.module'

import { IotService } from './iot.service'

@Module({
  imports: [HttpModule, RefreshModule],
  providers: [IotService, RedisService],
  exports: [IotService],
})
export class IotModule {}
