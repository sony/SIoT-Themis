import { Module } from '@nestjs/common'
import { RedisService } from 'src/redis.service'

import { DataController } from './data.controller'

@Module({
  controllers: [DataController],
  providers: [RedisService],
})
export class DataModule {}
