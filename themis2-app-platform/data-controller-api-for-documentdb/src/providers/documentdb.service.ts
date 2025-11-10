import { Injectable, OnApplicationShutdown, OnModuleInit } from '@nestjs/common'
import { Collection, Db, MongoClient } from 'mongodb'

@Injectable()
export class DocumentDBService implements OnModuleInit, OnApplicationShutdown {
  private client: MongoClient
  private db: Db
  async onModuleInit() {
    this.client = new MongoClient(`${process.env.MONGO_DATABASE_URL}&readPreference=secondaryPreferred`)
    await this.client.connect()
    this.db = this.client.db()
  }
  getCollection(collectionName: string): Collection {
    return this.db.collection(collectionName)
  }

  async onApplicationShutdown() {
    await this.client.close()
  }
}
