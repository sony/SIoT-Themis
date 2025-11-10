import { HttpModule } from '@nestjs/axios'
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'

import { PrismaService } from '../prisma.service'

import { SearchController } from './search.controller'
import { SearchService } from './search.service'

@Module({
  imports: [HttpModule, ConfigModule.forRoot()],
  controllers: [SearchController],
  providers: [SearchService, PrismaService],
})
export class SearchModule {}
