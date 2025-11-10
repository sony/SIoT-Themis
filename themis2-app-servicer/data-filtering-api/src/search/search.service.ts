import { HttpService } from '@nestjs/axios'
import {
  Injectable,
  ForbiddenException,
  BadGatewayException,
  UnprocessableEntityException,
  InternalServerErrorException,
  UnauthorizedException,
  Logger,
} from '@nestjs/common'
import { AxiosResponse } from 'axios'
import { firstValueFrom } from 'rxjs'
import { Prisma, Condition } from 'schema/prisma/client'

import { PrismaService } from '../prisma.service'

import { SearchQueryDto } from './dto/search-query.dto'

type CustomerWithType = Prisma.CustomerGetPayload<{
  include: { types: true }
}>
type TypeWithCondition = Prisma.TypeGetPayload<{
  include: { conditions: true }
}>

@Injectable()
export class SearchService {
  private logger = new Logger()
  constructor(
    private readonly httpService: HttpService,
    private readonly prisma: PrismaService,
  ) {}

  async search(query: SearchQueryDto, authorization: string): Promise<unknown> {
    const params = new URLSearchParams()
    Object.entries(query).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        params.append(String(key), String(value))
      }
    })
    const result = await this.prisma.customer.findMany({
      where: { apiKey: authorization },
      include: {
        types: {
          where: { type: query.type as string },
          include: { conditions: true },
        },
      },
    })
    if (result.length === 0) {
      throw new UnauthorizedException()
    } else if (result[0].types.length === 0) {
      throw new ForbiddenException()
    }
    const queryConditions: string[] = []
    result.forEach((customer: CustomerWithType) =>
      customer.types.forEach((type: TypeWithCondition) =>
        type.conditions.forEach((condition: Condition) => {
          queryConditions.push(`${condition.key}${condition.operator}${condition.value}`)
        }),
      ),
    )
    const queryString = queryConditions.join(';')
    let urlQueryParams = params.get('q')
    if (urlQueryParams) {
      params.set('q', (urlQueryParams += `;${queryString}`))
    } else {
      params.set('q', queryString)
    }
    try {
      const response: AxiosResponse = await firstValueFrom(
        this.httpService.get(`${process.env.DATA_CONTROLLER_API_URL}/search?${params.toString()}`, {
          headers: { authorization: `${process.env.BACKEND_API_KEY}` },
        }),
      )
      return response.data
    } catch (e) {
      this.logger.error(e)
      switch (e.response?.status) {
        case 401:
        case undefined:
          throw new BadGatewayException('Error from backend api')
        case 422:
          throw new UnprocessableEntityException('Request contains invalid query')
        default:
          throw new InternalServerErrorException()
      }
    }
  }
}
