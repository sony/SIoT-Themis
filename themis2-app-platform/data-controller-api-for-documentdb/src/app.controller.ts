import { Controller, Headers, Param, Body, BadRequestException, HttpCode, Post, Delete } from '@nestjs/common'

import { AppService } from './app.service'
import { RequestBodyDto } from './dto/app-request-body.dto'

@Controller('')
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Post()
  @HttpCode(201)
  async create(@Headers('collection') collection: string, @Body() body: RequestBodyDto): Promise<void> {
    if (!body.entityId || !body.entityType) {
      throw new BadRequestException('entityId and entityType are required')
    }
    await this.appService.create(body, collection)
  }

  @Post(':objectId')
  @HttpCode(204)
  async update(
    @Headers('collection') collection: string,
    @Param('objectId') objectId: string,
    @Body() body: Record<string, unknown>,
  ): Promise<void> {
    if (!collection) {
      throw new BadRequestException('collection is required')
    }

    await this.appService.update(collection, objectId, body)
  }

  @Delete(':objectId')
  @HttpCode(204)
  async delete(@Headers('collection') collection: string, @Param('objectId') objectId: string): Promise<void> {
    if (!collection) {
      throw new BadRequestException('collection is required')
    }
    await this.appService.delete(objectId, collection)
  }
}
