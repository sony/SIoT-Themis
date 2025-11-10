import { HttpService } from '@nestjs/axios'
import { Injectable, Logger } from '@nestjs/common'
import { AxiosResponse } from 'axios'
import { firstValueFrom } from 'rxjs'

import { BodyDto } from './dto/body-dto'

@Injectable()
export class AppService {
  constructor(private readonly httpService: HttpService) {}
  private grafanaEndpoint = process.env.GRAFANA_ENDPOINT as string
  private grafanaEndpointPushPath = process.env.GRAFANA_ENDPOINT_PUSH_PATH as string
  private logger = new Logger()

  // Convert sensor data to line protocol format
  convertToLineProtocol(sensorData: BodyDto): string {
    try {
      // Define variables to convert sensor data to line protocol format
      const measurement: string = sensorData.type
      const fields: string[] = this.createLineProtocolFields(sensorData)
      // UNIX timestamp converted sensorData.timestamp with nanoseconds
      const timestamp: number = new Date(sensorData.timestamp).getTime() * 1000000

      const lineProtocolConvertedData: string = `${measurement} ${fields.join(',')} ${timestamp}`
      // Return the line protocol converted data
      return lineProtocolConvertedData
    } catch (error) {
      this.logger.error(`convertToLineProtocol() ${error}`)
      throw error
    }
  }

  // Create the "fields" portion of the line protocol format using sensor data
  private createLineProtocolFields(sensorData: BodyDto): string[] {
    const fields: string[] = []
    fields.push(`id=${sensorData.id}`)

    // Add location data to fields array
    if (sensorData.location) {
      fields.push(`longitude=${sensorData.location.coordinates[0]}`)
      fields.push(`latitude=${sensorData.location.coordinates[1]}`)
    }

    // Retrieve all keys and values from sensorData.data
    for (const [key, value] of Object.entries(sensorData.data)) {
      // Add each key and key value to fields array
      fields.push(`"data.${key}"=${value}`)
    }

    // Add remaining data to fields array
    fields.push(`_version=${sensorData._version}`)
    fields.push(`_lfourId=${sensorData._lfourId}`)
    fields.push(`_txTime=${sensorData._txTime}`)
    fields.push(`_dataPayload="${sensorData._dataPayload}"`)
    fields.push(`_rssi=${sensorData._rssi}`)

    // Retrieve all keys and values from sensorData.serviceTags
    for (const [key, value] of Object.entries(sensorData.serviceTag)) {
      // Add each key and key value to fields array
      fields.push(`"serviceTag.${key}"="${value}"`)
    }

    // Return the line protocol converted fields data
    return fields
  }

  // Send line protocol converted data to Grafana
  async sendDataToGrafana(lineProtocolConvertedData: string, token: string) {
    try {
      // Request to send the line protocol converted data to Grafana
      const response: AxiosResponse = await firstValueFrom(
        this.httpService.post(
          `${this.grafanaEndpoint}/api/live/push/${this.grafanaEndpointPushPath}`,
          lineProtocolConvertedData,
          {
            headers: {
              authorization: `Bearer ${token}`,
            },
          },
        ),
      )
      if (process.env.NODE_ENV === 'development') {
        this.logger.log(`${response.status} ${response.statusText}`)
      }
    } catch (error) {
      this.logger.error(`Request Headers: ${error.config?.headers}`)
      this.logger.error(`Request Body: ${error.config?.data}`)
      this.logger.error(`Grafana Response: ${JSON.stringify(error.response?.data, null, 2)}`)
      this.logger.error(`Grafana Status Code: ${error.response?.status}`)
    }
  }
}
