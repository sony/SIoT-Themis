import { Injectable, OnApplicationShutdown, OnModuleInit } from '@nestjs/common'
import { PrismaClient } from 'schema/prisma/client/postgres'

@Injectable()
export class PostgresqlService extends PrismaClient implements OnModuleInit, OnApplicationShutdown {
  async onModuleInit() {
    await this.$connect()
  }
  async onApplicationShutdown() {
    await this.$disconnect()
  }
}
