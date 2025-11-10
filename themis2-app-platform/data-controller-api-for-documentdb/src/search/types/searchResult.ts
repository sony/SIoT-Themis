import type { SthX002f } from 'schema/prisma/client/mongodb'

export type SearchRawResult = Omit<
  SthX002f,
  | 'id'
  | 'timestamp'
  | 'version'
  | 'dataPayload'
  | 'lfourId'
  | 'rssi'
  | 'minver'
  | 'rssiDbm'
  | 'snr'
  | 'foffset'
  | 'delay'
  | 'nwpId'
  | 'stId'
  | 'stDevId'
> & {
  _id: {
    $oid: string
  }
  timestamp: Date
  _version: number
  _dataPayload: string
  _lfourId: number
  _rssi: number
  _minver: number
  // eslint-disable-next-line @typescript-eslint/naming-convention
  _rssi_dbm: number
  _snr: number
  _foffset: number
  _delay: number
  _nwpId: number
  _stId: number
  _stDevId: number
  _txTime: number
}

export type SearchResult = Omit<SearchRawResult, '_id' | 'entityId' | 'entityType' | 'timestamp'> & {
  _id: string
  id: string
  type: string
  timestamp: Date
}
