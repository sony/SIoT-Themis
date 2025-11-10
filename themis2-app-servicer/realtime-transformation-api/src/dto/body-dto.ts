export class BodyDto {
  id: string
  type: string
  timestamp: string
  location?: {
    type: string
    coordinates: [number, number]
  }
  data: Record<string | number | symbol, unknown>
  _version: number
  _txTime: number
  _dataPayload: string
  _lfourId: number
  _rssi: number
  serviceTag: Record<string | number | symbol, unknown>
}
