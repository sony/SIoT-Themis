import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'
import { createClient, RedisClientType } from 'redis'

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: RedisClientType
  private readonly ttl?: number
  private logger = new Logger()
  private ttlToUse: number | undefined
  private defaultRetries: number
  private defaultPrefix: string

  constructor(private configService: ConfigService) {
    const redisHost = this.configService.get<string>('REDIS_HOST') || 'redis'
    const redisPort = this.configService.get<number>('REDIS_PORT') || 6379
    const retries = this.configService.get<number>('REDIS_RETRIES') || 3
    const prefix = this.configService.get<string>('REDIS_PREFIX') || 'mqtt-message'
    this.defaultRetries = retries
    this.defaultPrefix = prefix
    const rawTTL = process.env.DUPLICATION_CHECK_TTL
    const ttl = rawTTL ? parseFloat(rawTTL) : NaN
    this.ttl = !isNaN(ttl) && ttl > 0 ? ttl * 1000 : undefined
    this.ttlToUse = this.ttl !== undefined && !isNaN(this.ttl) && this.ttl > 0 ? Math.floor(this.ttl) : undefined
    this.client = createClient({
      socket: {
        host: redisHost,
        port: redisPort,
        tls: process.env.TLS === 'false' ? false : true,
        reconnectStrategy: (retries) => Math.min(retries * 50, 500),
        connectTimeout: 10000,
      },
    })
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }

  async onModuleInit() {
    this.client.on('error', (err) => this.logger.error('Redis Client Error', err))
    this.client.on('connect', () => this.logger.debug('Redis connected successfully'))
    await this.client.connect()
    this.logger.debug('Redis client connected')
  }

  async onModuleDestroy() {
    await this.client.quit()
    this.logger.debug('Redis client disconnected')
  }

  async addToUniqueSet(value: string): Promise<boolean> {
    const key = `${this.defaultPrefix}:${value}`
    for (let i = 0; i < this.defaultRetries; i++) {
      try {
        if (process.env.NODE_ENV === 'development') {
          this.logger.debug(`Transaction params: key=${key}, ttl=${this.ttl}, value=${value}`)
        }
        const multi = this.client.multi()
        // eslint-disable-next-line @typescript-eslint/naming-convention
        multi.SET(key, '1', { NX: true })
        if (this.ttlToUse !== undefined) {
          multi.PEXPIRE(key, this.ttlToUse)
        }
        const results = await multi.exec()

        const setResult = results[0] as string | null
        const pexpireResult = results[1] as number

        if (process.env.NODE_ENV === 'development') {
          this.logger.debug(`Transaction results: set=${setResult}, pexpire=${pexpireResult}`)
          if (setResult === 'OK') {
            const ttlAfterSet = await this.client.ttl(key)
            this.logger.debug(`TTL of "${key}" after pexpire: ${ttlAfterSet}s`)
          }
        }

        if (setResult === 'OK') {
          if (process.env.NODE_ENV === 'development') {
            this.logger.debug(
              `Added "${value}" as key "${key}" ${this.ttlToUse !== undefined ? `with TTL ${this.ttlToUse}ms` : 'without TTL'}`,
            )
          }
          return true
        }
        this.logger.debug(`"${value}" already exists as key "${key}"`)
        return false
      } catch (error) {
        if (error.message.includes('OOM')) {
          this.logger.warn(`OOM for "${key}", retrying ${i + 1}/${this.defaultRetries}`)
          if (i === this.defaultRetries - 1) return false
          await this.sleep(800 * (i + 1))
          continue
        }
        if (error.message.includes('EXECABORT')) {
          this.logger.warn(`Transaction aborted for "${value}" as key "${key}": ${error.message}`)
          return false
        }
        if (i === this.defaultRetries - 1) {
          this.logger.error(
            `Failed to add "${value}" as key "${key}" after ${this.defaultRetries} retries: ${error.message}`,
          )
          throw error
        }
        if (process.env.NODE_ENV === 'development') {
          this.logger.debug(`Retry ${i + 1}/${this.defaultRetries} for adding "${value}" as key "${key}"`)
        }
        await this.sleep(800 * (i + 1))
      }
    }
    return false
  }

  async fillMemoryWithKeys(maxKeys: number): Promise<void> {
    if (process.env.NODE_ENV === 'production') {
      this.logger.warn(`fillMemoryWithKeys skipped in production enviroment`)
      return
    }
    let addedKeys = 0
    let oomRetries = 0
    this.logger.log(`Starting to fill memory with up to ${maxKeys} keys`)

    for (let index = 1; index <= maxKeys; index++) {
      const value = `${index}-${index}`
      const success = await this.addToUniqueSet(value)
      if (success) {
        addedKeys++
        oomRetries = 0
      } else {
        const memoryInfo = await this.client.info('memory')
        this.logger.warn(
          `Failed to add key "${this.defaultPrefix}:${value} at index ${index}, stopping. Memory: ${memoryInfo}"`,
        )
        if (oomRetries >= 50) {
          this.logger.log(`Max OOM retries reached (20), stopping`)
          break
        }
        oomRetries++
        await this.sleep(2000)
        continue
      }
      await this.sleep(50)
    }
    const memoryInfo = await this.client.info('memory')
    const keyCount = await this.client.dbSize()
    this.logger.log(`Finished filling memory. Added ${addedKeys} keys, total key in DB: ${keyCount}`)
    this.logger.log(`Final memory status: ${memoryInfo}`)
  }
}
