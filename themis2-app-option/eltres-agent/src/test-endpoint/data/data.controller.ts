import { Controller, Post, Body, Get, Query } from '@nestjs/common'
import { RedisService } from 'src/redis.service'

@Controller('data')
export class DataController {
  constructor(private readonly redisService: RedisService) {}

  /**
   * Redis set unique-data and store it with a 60s TTL if not a duplicate
   * @param value
   * @example { value : 'Test-duplicate'}
   * @returns
   */
  @Post('add')
  async addData(@Body('value') value: string) {
    if (!value) {
      return {
        message: 'Value is required',
        status: 'error',
      }
    }

    const isAdded = await this.redisService.addToUniqueSet(value)
    return {
      message: isAdded ? `Data "${value}" added successfully` : `Data "${value}" is a duplicate`,
      status: isAdded ? 'success' : 'duplicate',
    }
  }

  @Get('fill-memory')
  async fillMemory(@Query('maxKeys') maxKeys: number) {
    await this.redisService.fillMemoryWithKeys(maxKeys)
    return { message: 'Memory fill completed' }
  }
}
