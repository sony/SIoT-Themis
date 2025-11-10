import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'

import { AppController } from './app.controller'
import { AppService } from './app.service'
import { ProvidersModule } from './providers/providers.module'
import { SearchModule } from './search/search.module'

@Module({
  imports: [SearchModule, ProvidersModule, ConfigModule.forRoot()],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
