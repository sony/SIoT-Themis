import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'

import { NotifyModule } from './notify/notify.module'

@Module({
  imports: [NotifyModule, ConfigModule.forRoot()],
})
export class AppModule {}
