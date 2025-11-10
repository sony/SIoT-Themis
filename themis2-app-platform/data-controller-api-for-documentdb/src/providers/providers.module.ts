import { Global, Module } from '@nestjs/common'

import { DocumentDBService } from './documentdb.service'
import { PostgresqlService } from './postgresql.service'

@Global()
@Module({
  providers: [PostgresqlService, DocumentDBService],
  exports: [PostgresqlService, DocumentDBService],
})
export class ProvidersModule {}
