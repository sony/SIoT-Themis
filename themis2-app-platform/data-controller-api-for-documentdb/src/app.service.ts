import { BadRequestException, Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common'
import { DeleteResult, ObjectId, UpdateResult } from 'mongodb'

import { DocumentDBService } from './providers/documentdb.service'
import { PostgresqlService } from './providers/postgresql.service'

type Payload = {
  id: string
  type: string
  [key: string]: unknown
}

@Injectable()
export class AppService {
  constructor(
    private readonly documentdb: DocumentDBService,
    private readonly postgres: PostgresqlService,
  ) {}

  async create(payload: Payload, collection: string): Promise<void> {
    const insertToCollection = async (collectionName: string) => {
      try {
        await this.documentdb.getCollection(collectionName).insertOne(payload)
        return
      } catch (err) {
        console.error('DB insert failed:', err)
        throw new InternalServerErrorException()
      }
    }

    const encodeCollectionName = (name: string): string => {
      return 'sth_' + name.replace(/\//g, 'x002f')
    }

    const encoded = encodeCollectionName(collection)
    await insertToCollection(encoded)
  }

  async update(collection: string, objectId: string, body: Record<string, unknown>): Promise<void> {
    const updateSet = {
      ...Object.fromEntries(Object.entries(body.data || {}).map(([k, v]) => [`data.${k}`, v])),
      ...Object.fromEntries(Object.entries(body.serviceTag || {}).map(([k, v]) => [`serviceTag.${k}`, v])),
      ...Object.fromEntries(Object.entries(body).filter(([k]) => k !== 'data' && k !== 'serviceTag')),
    }

    const filter = {
      _id: new ObjectId(objectId),
    }

    const mainCollectionName = 'sth_' + collection.replace(/\//g, 'x002f')
    const [mainResult] = await Promise.all([this.updateOneWithCheck(mainCollectionName, filter, updateSet)])
    if (mainResult.modifiedCount === 0) {
      throw new NotFoundException()
    }

    if (mainResult.acknowledged === false) {
      throw new BadRequestException()
    }
  }

  async delete(objectId: string, collection: string): Promise<void> {
    const encodedCollection: string = 'sth_' + collection.replace(/\//g, 'x002f')
    const filter: Record<string, unknown> = { _id: new ObjectId(objectId) }

    const result = await this.safeDelete(encodedCollection!, filter!)

    if (result.deletedCount === 0) {
      throw new NotFoundException()
    }
  }

  private async updateOneWithCheck(
    collectionName: string,
    filter: Record<string, unknown>,
    updateSet: Record<string, unknown>,
  ): Promise<UpdateResult> {
    try {
      return await this.documentdb.getCollection(collectionName).updateOne(filter, { $set: updateSet })
    } catch (error) {
      if (error.name === 'BSONError') {
        throw new BadRequestException()
      }
      throw new InternalServerErrorException()
    }
  }
  private async safeDelete(encodedCollection: string, filter: Record<string, unknown>): Promise<DeleteResult> {
    try {
      return await this.documentdb.getCollection(encodedCollection).deleteOne(filter)
    } catch (error) {
      if (error.name === 'BSONError') {
        throw new BadRequestException()
      }
      throw new InternalServerErrorException()
    }
  }
}
