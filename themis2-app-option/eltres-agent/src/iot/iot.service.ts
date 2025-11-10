import * as fs from 'fs'

import { toUtf8 } from '@aws-sdk/util-utf8-browser'
import { HttpService } from '@nestjs/axios'
import { Injectable, OnModuleInit, Logger } from '@nestjs/common'
import { ICrtError } from 'aws-crt'
import { mqtt5, iot } from 'aws-iot-device-sdk-v2'
import { AxiosResponse } from 'axios'
import { firstValueFrom } from 'rxjs'
import { RedisService } from 'src/redis.service'
import { v4 as uuidv4 } from 'uuid'

import { RefreshService } from '../refresh/refresh.service'

type Range = {
  from: number
  to: number
}

type FieldDefinition = {
  offset: number
  length: number
  bias?: number
  gain?: number
}

type Definition = Record<string, FieldDefinition>

type TypedDefinition = {
  type: string
  definition: Definition
}

type Mappings = {
  groups: Record<string, Array<number | Range>>
  definitions: Record<string, TypedDefinition>
}

type NodeDefinition = Record<string, TypedDefinition>

type ServiceTag = {
  [key: string]: string
}

type Payload = {
  lfourId: number
  txTime: number
  serviceTag: ServiceTag
  dataPayload: string
  [key: string]: number | string | object
}

type NgsiV2 = {
  id: number
  principalId: string | undefined
  type: string
  timestamp: string
  location?: { type: string; coordinates: [number, number] }
  data: {
    [key: string]: number
  }
  serviceTag: ServiceTag
  [key: string]: string | number | object | undefined
}

@Injectable()
export class IotService implements OnModuleInit {
  constructor(
    private readonly refreshService: RefreshService,
    private readonly httpService: HttpService,
    private readonly redisService: RedisService,
  ) {}
  private device: mqtt5.Mqtt5Client
  private logger = new Logger()
  private servicerData: Record<string, number> = {}

  onModuleInit() {
    this.device = new mqtt5.Mqtt5Client(this.buildMqttConfig())

    this.addEventHandlers(this.device)

    this.device.start()
    this.servicerData = this.refreshService.getServicerData()
  }

  private buildMqttConfig() {
    return iot.AwsIotMqtt5ClientConfigBuilder.newDirectMqttBuilderWithMtlsFromPath(
      process.env.HOST!,
      process.env.CERT_PATH!,
      process.env.KEY_PATH!,
    )
      .withCertificateAuthorityFromPath(undefined, process.env.CA_PATH)
      .withPort(parseInt(process.env.PORT!, 10))
      .withConnectProperties({
        keepAliveIntervalSeconds: 30,
        clientId: 'eltres-agent-' + uuidv4(),
      })
      .build()
  }

  private validateLocation(latitude?: number, longitude?: number): boolean {
    if (latitude === undefined || longitude === undefined) {
      return false
    }
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
  }

  private processTimestamp(txTime: number): string {
    const integerPart = Math.floor(txTime)
    const timeStr = integerPart.toString()
    const isMilliseconds = timeStr.length >= 12
    const timestampInMs = isMilliseconds ? txTime : txTime * 1000
    return new Date(timestampInMs).toISOString()
  }

  private toNgsiV2(payload: Payload, nodeDefinition: NodeDefinition): NgsiV2 | undefined {
    const id = payload.lfourId

    if (!nodeDefinition[id]) return
    const parsedData = this.parse(payload.dataPayload, nodeDefinition[id].definition)
    // eslint-disable-next-line prefer-const
    let { latitude, longitude, ...otherData } = parsedData
    const { serviceTag, ...others } = payload
    const isValidLocation = this.validateLocation(latitude, longitude)

    if (!isValidLocation && (latitude !== undefined || longitude !== undefined)) {
      latitude = 90
      longitude = 0
    }

    const convertedTxTime = this.processTimestamp(payload.txTime)

    return {
      id,
      principalId: payload.principalId != null ? String(payload.principalId) : undefined,
      type: nodeDefinition[id].type,
      timestamp: convertedTxTime,
      ...(isValidLocation && {
        location: { type: 'Point', coordinates: [longitude, latitude] },
      }),
      data: {
        ...otherData,
        ...(latitude !== undefined && {
          latitude,
        }),
        ...(longitude !== undefined && {
          longitude,
        }),
      },
      //  Change key to _key
      ...Object.fromEntries(Object.entries(others).map(([k, v]) => [`_${k}`, v])),
      serviceTag: serviceTag,
    }
  }

  private async upsertOrionEntity(ngsiV2: NgsiV2 | undefined) {
    try {
      const { id, principalId, type, timestamp, location, data, serviceTag, ...rest } = ngsiV2!
      const normalizedNgsiV2 = {
        id: String(id),
        type,
        timestamp: {
          type: 'DateTime',
          value: timestamp,
        },
        ...(location && {
          location: {
            type: 'geo:json',
            value: {
              type: location.type,
              coordinates: location.coordinates,
            },
          },
        }),
        data: {
          type: 'StructuredValue',
          value: data,
        },
        ...Object.fromEntries(Object.entries(rest).map(([k, v]) => [k, this.toNgsiV2Field(v)])),
        serviceTag: {
          type: 'StructuredValue',
          value: serviceTag,
        },
      }

      this.servicerData = this.refreshService.getServicerData()
      const serviceId = this.servicerData[String(principalId)]
      if (!serviceId) {
        this.logger.error(`No serviceId found for node ${principalId}`)
        return
      }

      this.logger.debug(`Fiware-ServicePath: /servicers/${serviceId}`)
      const headers: Record<string, string> = {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        'Fiware-Service': process.env.FIWARE_SERVICE!,
        // eslint-disable-next-line @typescript-eslint/naming-convention
        'Fiware-ServicePath': `/servicers/${serviceId}`,
      }

      const response: AxiosResponse = await firstValueFrom(
        this.httpService.post(
          `${process.env.ORION_URL}/v2/op/update`,
          {
            actionType: 'append',
            entities: [normalizedNgsiV2],
          },
          { headers },
        ),
      )

      if (process.env.NODE_ENV === 'development') {
        console.debug('Orion Response:', response!.status)
      }
    } catch (error) {
      this.logger.error(`Request Headers: ${error.request?._header}`)
      this.logger.error(`Request Body: ${error.config?.data}`)
      this.logger.error(`Orion Response: ${JSON.stringify(error.response?.data, null, 2)}`)
      this.logger.error(`Orion Status Code: ${error.response?.status}`)
    }
  }

  private toNgsiV2Field(value: string | number | object | undefined): {
    type: string
    value: number | string | object
  } {
    switch (typeof value) {
      case 'number':
        return { type: 'Integer', value }
      case 'string':
        return { type: 'Text', value }
      case 'object':
        return { type: 'StructuredValue', value }
      default:
        throw new Error('Unsupported type')
    }
  }

  private addEventHandlers(device: mqtt5.Mqtt5Client) {
    const nodeDefinition = this.loadMappings(process.env.MAPPINGS_PATH!)

    device.on('messageReceived', async (eventData: mqtt5.MessageReceivedEvent) => {
      if (!eventData.message.payload) return

      const payload = JSON.parse(toUtf8(new Uint8Array(eventData.message.payload as ArrayBuffer)))
      const messageKey = `${payload.lfourId}-${payload.txTime}`
      const isStored = await this.redisService.addToUniqueSet(messageKey)
      if (!isStored) {
        return
      }
      const ngsiV2 = this.toNgsiV2(payload, nodeDefinition)
      if (!ngsiV2) return

      const analysisResult = await this.applyRealtimeAnalyzers(ngsiV2)

      this.upsertOrionEntity(analysisResult)
    })

    device.on('attemptingConnect', () => {
      this.logger.debug('Attempting Connect event')
    })

    device.on('connectionSuccess', () => {
      this.logger.debug('Connected to AWS IoT')
      const topics = JSON.parse(process.env.TOPICS!) as string[]
      const subscriptions = topics.map((topic) => ({
        topicFilter: topic,
        qos: mqtt5.QoS.AtLeastOnce,
      }))
      device.subscribe({ subscriptions })
    })

    device.on('connectionFailure', (eventData: mqtt5.ConnectionFailureEvent) => {
      this.logger.error('Connection failure event: ' + eventData.error.toString())
      if (eventData.connack) {
        this.logger.error('Connack: ' + JSON.stringify(eventData.connack))
      }
    })

    device.on('disconnection', (eventData: mqtt5.DisconnectionEvent) => {
      this.logger.error('Disconnection event: ' + eventData.error.toString())
      if (eventData.disconnect !== undefined) {
        this.logger.error('Disconnect packet: ' + JSON.stringify(eventData.disconnect))
      }
    })

    device.on('stopped', () => {
      this.logger.debug('Stopped event')
    })

    device.on('error', (error: ICrtError) => {
      this.logger.error('Error event: ' + error.toString())
    })
  }

  async applyRealtimeAnalyzers(ngsiV2: NgsiV2): Promise<NgsiV2> {
    let result = ngsiV2
    for (const servicer of this.refreshService.getCachedServicers()) {
      //  Skip unrelated servicer
      if (!servicer.principalIds.includes(String(ngsiV2.principalId))) {
        continue
      }

      try {
        const response: AxiosResponse = await firstValueFrom(this.httpService.post(servicer.url!, result))
        result = this.mergeData(result, response.data.data)
      } catch (error) {
        this.logger.error(`Error posting to URL: ${servicer.url}`)
        this.logger.error(`Request body: ${JSON.stringify(ngsiV2, null, 2)}`)
        this.logger.error(`Error message: ${error.message}`)
      }
    }

    return result
  }

  private mergeData(original: NgsiV2, data: Record<string, number>) {
    return {
      ...original,
      data: {
        ...original.data,
        ...data,
      },
    }
  }

  private loadMappings(mappingsPath: string): NodeDefinition {
    const { groups, definitions }: Mappings = JSON.parse(fs.readFileSync(mappingsPath, 'utf8'))

    const nodeDefinition: NodeDefinition = {}
    for (const [group, ids] of Object.entries(groups)) {
      ids.forEach((id) => {
        if (typeof id === 'number') {
          nodeDefinition[id] = definitions[group]
          return
        }

        for (let i = id.from; i <= id.to; i++) {
          nodeDefinition[i] = definitions[group]
        }
      })
    }
    return nodeDefinition
  }

  private toBinary(hexString: string): string {
    return [...hexString].map((c) => parseInt(c, 16).toString(2).padStart(4, '0')).join('')
  }

  private parse(payload: string, definition: Definition): Record<string, number> {
    const parsedData: Record<string, number> = {}

    const binaryPayload = this.toBinary(payload)
    Object.entries(definition).forEach(([field, fieldDefinition]) => {
      const binaryPart = binaryPayload.slice(fieldDefinition.offset, fieldDefinition.offset + fieldDefinition.length)
      const rawValue = parseInt(binaryPart, 2)

      const gain = fieldDefinition.gain ?? 1
      const bias = fieldDefinition.bias ?? 0
      const value = rawValue * gain + bias
      parsedData[field] = value
    })
    return parsedData
  }
}
