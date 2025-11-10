import { Controller, Post, Delete, Patch, Get, Param, Body, Headers, HttpCode, UseGuards } from '@nestjs/common'

import { NotifyBodyDto, NotifyPatchBodyDto } from './dto/notify-body.dto'
import { NotifyGuard } from './notify.guard'
import { NotifyService, BulkResult } from './notify.service'

@Controller('notify')
@UseGuards(NotifyGuard)
export class NotifyController {
  constructor(private readonly notifyService: NotifyService) {}

  @Delete('bulk')
  async deleteBulkNotifications(
    @Headers('Fiware-Service') fiwareService: string,
    @Headers('Fiware-ServicePath') fiwareServicePath: string,
  ): Promise<BulkResult> {
    return await this.notifyService.deleteSubscriptions(fiwareService, fiwareServicePath)
  }

  @Post()
  async createNotifications(
    @Headers('Fiware-Service') fiwareService: string,
    @Headers('Fiware-ServicePath') fiwareServicePath: string,
    @Body() body: NotifyBodyDto,
  ): Promise<{ id: string }> {
    const newSubscriptionId = await this.notifyService.createSubscription(
      body.type,
      body.url,
      body.condition,
      fiwareService,
      fiwareServicePath,
    )
    return { id: newSubscriptionId }
  }

  @Delete(':id')
  @HttpCode(204)
  async deleteNotifications(
    @Headers('Fiware-Service') fiwareService: string,
    @Headers('Fiware-ServicePath') fiwareServicePath: string,
    @Param('id') subscriptionId: string,
  ): Promise<void> {
    await this.notifyService.deleteSubscription(fiwareService, fiwareServicePath, subscriptionId)
  }

  @Patch(':id')
  @HttpCode(204)
  async updateNotifications(
    @Headers('Fiware-Service') fiwareService: string,
    @Headers('Fiware-ServicePath') fiwareServicePath: string,
    @Param('id') subscriptionId: string,
    @Body() body: NotifyPatchBodyDto,
  ): Promise<void> {
    await this.notifyService.updateSubscription(subscriptionId, body, fiwareService, fiwareServicePath)
  }

  @Get()
  @HttpCode(200)
  async listNotifications(
    @Headers('Fiware-Service') fiwareService: string,
    @Headers('Fiware-ServicePath') fiwareServicePath: string,
  ): Promise<{ id: string }[]> {
    const servicer = await this.notifyService.getServicer(fiwareServicePath)
    return servicer.subscriptions.map((subscription) => ({ id: subscription.subscriptionId }))
  }
}
