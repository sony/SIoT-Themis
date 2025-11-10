import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { ScheduleModule } from '@nestjs/schedule'

import { IotModule } from './iot/iot.module'
import { RedisService } from './redis.service'
import { RefreshModule } from './refresh/refresh.module'
import { SchedulerModule } from './scheduler/scheduler.module'
import { DataModule } from './test-endpoint/data/data.module'

@Module({
  imports: [
    IotModule,
    ConfigModule.forRoot({
      envFilePath: '.env',
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),
    SchedulerModule,
    RefreshModule,
    ...(process.env.NODE_ENV == 'development' ? [DataModule] : []),
  ],
  providers: [RedisService],
})
export class AppModule {}
