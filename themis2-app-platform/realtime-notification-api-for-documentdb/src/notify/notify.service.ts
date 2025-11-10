import { HttpService } from '@nestjs/axios'
import { Injectable, InternalServerErrorException, BadRequestException, NotFoundException } from '@nestjs/common'
import { point } from '@turf/helpers'
import { circle } from '@turf/turf'
import { AxiosResponse, AxiosError } from 'axios'
import { firstValueFrom } from 'rxjs'
import { PrismaClient as PostgresClient } from 'schema/prisma/client/postgres'

import { NotifyPatchBodyDto } from './dto/notify-body.dto'

import type { Prisma, Subscription } from 'schema/prisma/client/postgres'

type OrionSubscriptionCondition = {
  expression?: {
    georel?: string
    geometry?: string
    coords?: string
    q?: string
  }
  attrs?: string[]
}

type OrionSubscriptionEntity = { idPattern?: string; type: string }

type OrionSubscription = {
  subject: {
    entities: OrionSubscriptionEntity[]
    condition?: OrionSubscriptionCondition
  }
  notification: {
    http: {
      url: string
    }
    attrsFormat: string
  }
}

type UpdateOrionSubscription = Omit<OrionSubscription, 'notification'> &
  Partial<Pick<OrionSubscription, 'notification'>>

export type BulkResult = {
  count: number
  successes: { id: string }[]
  failures: { id: string; statusCode: number }[]
}

@Injectable()
export class NotifyService {
  private prisma = new PostgresClient()

  constructor(private readonly httpService: HttpService) {}

  private extractServicerIdFromServicePath(fiwareServicePath: string): number {
    const match = fiwareServicePath.match(/^\/servicers\/(\d+)$/)
    if (!match) {
      throw new BadRequestException('Invalid service path format.')
    }

    return parseInt(match[1], 10)
  }

  async getServicer(fiwareServicePath: string): Promise<{ id: number; subscriptions: Subscription[] }> {
    const id = this.extractServicerIdFromServicePath(fiwareServicePath)
    const servicer = await this.prisma.servicer.findUnique({
      where: { id },
      select: {
        id: true,
        subscriptions: true,
      },
    })

    if (!servicer) {
      throw new NotFoundException(`Servicer not found for path: ${fiwareServicePath}`)
    }

    return servicer
  }

  private convertFiwareHeaders(fiwareService: string, fiwareServicePath: string): Record<string, string> {
    return {
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'Fiware-Service': fiwareService,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'Fiware-ServicePath': fiwareServicePath,
    }
  }

  private handleOrionError(error: unknown): never {
    if (error instanceof AxiosError) {
      if (error.response?.status === 404) {
        throw new NotFoundException()
      } else if (error.response?.status && error.response.status >= 400 && error.response.status < 500) {
        throw new BadRequestException()
      } else {
        throw new InternalServerErrorException()
      }
    } else {
      throw new InternalServerErrorException()
    }
  }

  private async createOrionSubscription(
    type: string,
    url: string,
    condition: OrionSubscriptionCondition | undefined,
    fiwareService: string,
    fiwareServicePath: string,
  ): Promise<string> {
    const entities = [{ idPattern: '.*', type: type }]
    const headers = this.convertFiwareHeaders(fiwareService, fiwareServicePath)
    let radius: number | undefined = undefined
    if (condition?.expression?.geometry === 'point') {
      const match = condition.expression.georel?.match(/maxDistance:(\d+)/)
      if (!match) throw new BadRequestException()
      radius = Number(match[1])
      if (!radius || !condition.expression.coords) throw new BadRequestException()
      if (radius <= 10000000) {
        const generatedPolygon = generatePseudoCirclePolygon(radius, condition.expression.coords)
        condition.expression.geometry = 'polygon'
        condition.expression.georel = 'coveredBy'
        condition.expression.coords = generatedPolygon
      }
    }
    const orionSubscription: OrionSubscription = {
      subject: {
        entities,
        condition: condition,
      },
      notification: {
        http: {
          url: url,
        },
        attrsFormat: 'simplifiedKeyValues',
      },
    }

    if (radius && !(radius <= 10000000)) {
      delete orionSubscription.subject.condition?.expression?.georel
      delete orionSubscription.subject.condition?.expression?.geometry
      delete orionSubscription.subject.condition?.expression?.coords
      if (
        orionSubscription.subject.condition?.expression &&
        Object.keys(orionSubscription.subject.condition.expression).length === 0
      ) {
        delete orionSubscription.subject.condition?.expression
      }
      if (orionSubscription.subject.condition && Object.keys(orionSubscription.subject.condition).length === 0) {
        delete orionSubscription.subject.condition
      }
    }

    try {
      const response: AxiosResponse = await firstValueFrom(
        this.httpService.post(`${process.env.ORION_URL}/v2/subscriptions`, orionSubscription, { headers }),
      )
      return response.headers['location'].split('/').pop()
    } catch (error) {
      this.handleOrionError(error)
    }
  }

  async createSubscription(
    type: string,
    url: string,
    condition: OrionSubscriptionCondition | undefined,
    fiwareService: string,
    fiwareServicePath: string,
  ): Promise<string> {
    const servicer = await this.getServicer(fiwareServicePath)
    const orionSubscriptionId = await this.createOrionSubscription(
      type,
      url,
      condition,
      fiwareService,
      fiwareServicePath,
    )

    try {
      await this.insertDbSubscription(servicer.id, orionSubscriptionId, type)
    } catch (error) {
      console.error('Failed to create subscription', error)
      await this.deleteOrionSubscription(fiwareService, fiwareServicePath, orionSubscriptionId)
      throw error
    }

    return orionSubscriptionId
  }

  private async insertDbSubscription(servicerId: number, orionSubscriptionId: string, type: string): Promise<void> {
    try {
      await this.prisma.subscription.create({
        data: {
          servicerId,
          subscriptionId: orionSubscriptionId,
          type,
        },
      })
    } catch (error) {
      console.error('Failed to insert subscription to database:', error)
      throw new InternalServerErrorException()
    }
  }

  private async deleteOrionSubscription(
    fiwareService: string,
    fiwareServicePath: string,
    subscriptionId: string,
  ): Promise<void> {
    try {
      const headers = this.convertFiwareHeaders(fiwareService, fiwareServicePath)
      await firstValueFrom(
        this.httpService.delete(`${process.env.ORION_URL}/v2/subscriptions/${subscriptionId}`, { headers }),
      )
    } catch (error) {
      this.handleOrionError(error)
    }
  }

  private async deleteDbSubscription(subscriptionId: string): Promise<void> {
    try {
      await this.prisma.subscription.delete({
        where: { subscriptionId },
      })
    } catch (error) {
      console.error('Failed to delete subscription from database:', error)
      throw new InternalServerErrorException()
    }
  }

  async updateSubscription(
    subscriptionId: string,
    body: NotifyPatchBodyDto,
    fiwareService: string,
    fiwareServicePath: string,
  ): Promise<void> {
    await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      let type = body.type
      let condition = body.condition

      // Get current subscription data with lock to prevent deadlocks
      const dbSubscription = await this.getDbSubscriptionWithLock(tx, subscriptionId)

      // Use current type and condition if these are not specified
      if (!type) {
        type = dbSubscription.type
      }
      if (!condition) {
        // Get current subscription data from Orion using subscription ID and Fiware-ServicePath
        const orionSubscription = await this.getOrionSubscription(subscriptionId, fiwareServicePath, fiwareService)
        condition = orionSubscription!.subject.condition
      }

      const entities: OrionSubscriptionEntity[] = [{ idPattern: '.*', type: type }]

      // Update Orion subscription first
      await this.updateOrionSubscription(
        subscriptionId,
        entities,
        condition,
        body.url,
        fiwareService,
        fiwareServicePath,
      )

      // Update DB subscription if type is provided
      if (body.type) {
        await tx.subscription.update({
          where: { subscriptionId },
          data: {
            type: body.type,
          },
        })
      }
    })
  }

  private async updateOrionSubscription(
    subscriptionId: string,
    entities: OrionSubscriptionEntity[],
    condition: OrionSubscriptionCondition | undefined,
    url: string,
    fiwareService: string,
    fiwareServicePath: string,
  ): Promise<void> {
    let radius: number | undefined
    if (condition?.expression?.geometry === 'point') {
      const match = condition.expression.georel?.match(/maxDistance:(\d+)/)
      if (!match) throw new BadRequestException()
      radius = Number(match[1])
      if (!radius || !condition.expression.coords) throw new BadRequestException()
      if (radius <= 10000000) {
        const generatedPolygon = generatePseudoCirclePolygon(radius, condition.expression.coords)
        condition.expression.geometry = 'polygon'
        condition.expression.georel = 'coveredBy'
        condition.expression.coords = generatedPolygon
      }
    }
    const orionSubscription: UpdateOrionSubscription = {
      subject: {
        entities: entities,
        condition: condition,
      },
      ...(url
        ? {
            notification: {
              http: { url },
              attrsFormat: 'simplifiedKeyValues',
            },
          }
        : {}),
    }
    if (radius && !(radius <= 10000000)) {
      delete orionSubscription.subject.condition?.expression?.georel
      delete orionSubscription.subject.condition?.expression?.geometry
      delete orionSubscription.subject.condition?.expression?.coords
      if (
        orionSubscription.subject.condition?.expression &&
        Object.keys(orionSubscription.subject.condition.expression).length === 0
      ) {
        delete orionSubscription.subject.condition?.expression
      }
      if (orionSubscription.subject.condition && Object.keys(orionSubscription.subject.condition).length === 0) {
        delete orionSubscription.subject.condition
      }
    }
    try {
      const headers = this.convertFiwareHeaders(fiwareService, fiwareServicePath)
      await firstValueFrom(
        this.httpService.patch(`${process.env.ORION_URL}/v2/subscriptions/${subscriptionId}`, orionSubscription, {
          headers,
        }),
      )
    } catch (error) {
      this.handleOrionError(error)
    }
  }

  private async getOrionSubscription(
    subscriptionId: string,
    fiwareServicePath: string,
    fiwareService: string,
  ): Promise<OrionSubscription> {
    try {
      const headers = this.convertFiwareHeaders(fiwareService, fiwareServicePath)
      const response: AxiosResponse<OrionSubscription> = await firstValueFrom(
        this.httpService.get(`${process.env.ORION_URL}/v2/subscriptions/${subscriptionId}`, { headers }),
      )
      return response.data
    } catch (error) {
      this.handleOrionError(error)
    }
  }

  private async getDbSubscriptionWithLock(
    tx: Prisma.TransactionClient,
    subscriptionId: string,
  ): Promise<{ type: string }> {
    const subscriptions: { type: string }[] = await tx.$queryRaw`
      SELECT type
      FROM subscriptions
      WHERE subscription_id = ${subscriptionId}
      FOR UPDATE
    `

    if (!subscriptions[0]) {
      throw new NotFoundException()
    }

    return subscriptions[0]
  }

  async deleteSubscriptions(fiwareService: string, fiwareServicePath: string): Promise<BulkResult> {
    const successes: { id: string }[] = []
    const failures: { id: string; statusCode: number }[] = []
    let subscriptions: Subscription[]

    try {
      const servicer = await this.getServicer(fiwareServicePath)
      subscriptions = servicer.subscriptions
    } catch (error) {
      console.error('Failed to delete subscriptions', error)
      throw new InternalServerErrorException('Failed to delete subscriptions')
    }

    for (const subscription of subscriptions) {
      const subscriptionId = subscription.subscriptionId
      try {
        await this.deleteOrionSubscription(fiwareService, fiwareServicePath, subscriptionId)
      } catch (error) {
        if (error instanceof NotFoundException) {
          console.warn(`Orion Subscription ${subscriptionId} not found`)
        } else {
          console.error(`Error deleting orion subscription ${subscriptionId} :`, error)
          failures.push({ id: subscriptionId, statusCode: error?.response?.status || 500 })
          continue
        }
      }

      try {
        await this.deleteDbSubscription(subscriptionId)
      } catch (error) {
        console.error(`Error deleting subscription ${subscriptionId} from DB:`, error)
        failures.push({ id: subscriptionId, statusCode: 500 })
        continue
      }

      successes.push({ id: subscriptionId })
    }

    return { count: successes.length + failures.length, successes, failures }
  }

  async deleteSubscription(fiwareService: string, fiwareServicePath: string, subscriptionId: string): Promise<void> {
    await this.deleteOrionSubscription(fiwareService, fiwareServicePath, subscriptionId)
    await this.deleteDbSubscription(subscriptionId)
  }
}

function generatePseudoCirclePolygon(radius: number, coords: string) {
  const parsedCoords: number[] = coords.split(',').map((str) => {
    const num = Number(str)
    if (isNaN(num)) throw new BadRequestException()
    return num
  })
  const parsedPoint = point([parsedCoords[1], parsedCoords[0]])
  const options = {
    steps: 64,
    units: 'kilometers' as const,
  }
  const circles = circle(parsedPoint, radius ? radius : 0, options)
  coords = circles.geometry.coordinates[0]
    .map(([lng, lat]: [number, number]) => {
      lng = ((((lng + 180) % 360) + 360) % 360) - 180
      return `${lat},${lng}`
    })
    .join(';')
  return coords
}
