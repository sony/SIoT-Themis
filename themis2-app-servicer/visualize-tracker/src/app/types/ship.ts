export type Ship = {
  _id?: string
  id: string
  type: string
  timestamp: string
  location?: {
    type: string
    coordinates: [number, number]
  }
  data: {
    temperature?: number
    humidity?: number
    sos: 0 | 1 | 2 | 3
    alert?: number
  }
  _version: number
  _txTime: number
  _dataPayload: string
  _lfourId: number
  _rssi: number
  _minver?: number
  _rssiDbm?: number
  _snr?: number
  _foffset?: number
  _delay?: number
  _nwpId?: number
  _stId?: number
  _stDevId?: number
  serviceTag: {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    service_id: string
    serviceId: string
  }
}
