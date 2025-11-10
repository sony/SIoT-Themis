import * as fs from 'fs'

import axios from 'axios'
import * as cron from 'node-cron'
import * as yargs from 'yargs'

import 'dotenv/config'

type UpdateData = { data: Record<string, number> }

type SearchData = {
  /* eslint-disable @typescript-eslint/naming-convention */
  _id: string
  id: string
  type: string
  timestamp: string
  location?: {
    type: string
    coordinates: [number, number]
  }
  data: Record<string, number>
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
  serviceTag: Record<string, string>
  /* eslint-enable */
  [key: string]: unknown
}

const argv = yargs
  .option('type', {
    type: 'string',
    description: 'Specify the entity type of the target data.',
    demandOption: true,
  })
  .option('key', {
    type: 'string',
    description: 'Specify the key to be evaluated for alerting.',
    demandOption: true,
  })
  .option('daemon', {
    type: 'boolean',
    description: 'Perform cron activation.',
    demandOption: false,
    default: false,
  })
  .option('interval', {
    type: 'string',
    description:
      'Cron execution interval. Specify in Cron Syntax format. (https://www.npmjs.com/package/node-cron#cron-syntax)',
    demandOption: false,
  })
  .parseSync()

const sum = function (numbers: number[]) {
  return numbers.reduce(function (prev: number, current: number) {
    return prev + current
  })
}

function getNestedValue(obj: SearchData, key: string): number | undefined {
    const keys = key.split('.');
    if (keys.length === 1) {
        const value = obj[key];
        return typeof value === 'number' ? value : undefined;
    }

    let current: unknown = obj;
    for (let i = 0; i < keys.length - 1; i++) {
        const currentKey = keys[i];
        if (current === null || typeof current !== 'object') {
            return undefined;
        }
        current = (current as Record < string, unknown > )[currentKey];
        if (current === undefined) {
            return undefined;
        }
    }
    const finalKey = keys[keys.length - 1];
    const value = (current as Record < string, unknown > )[finalKey];
    return typeof value === 'number' ? value : undefined;
}

async function search(type: string, nextProcessingFrom: string | null): Promise<SearchData[]> {
  const params = new URLSearchParams()
  params.append('type', type)
  if (nextProcessingFrom) params.append('q', `timestamp>=${nextProcessingFrom}`)
  const url = `${process.env.DATA_CONTROLLER_API_ORIGIN!}/search?${params}`
  const headers = { authorization: process.env.DATA_CONTROLLER_API_KEY! }

  const results: SearchData[] = await (await axios.get(url, { headers })).data
  return results.sort((a, b) => (a.timestamp > b.timestamp ? 1 : -1))
}

async function update(objectId: string, updateData: UpdateData): Promise<void> {
  const url = `${process.env.DATA_CONTROLLER_API_ORIGIN!}/${objectId}`
  const headers = { authorization: process.env.DATA_CONTROLLER_API_KEY! }
  await axios.post(url, updateData, { headers })
}

async function doMain() {
  const savePath: string = `${process.env.NEXT_PROCESSING_FOLDER}/next-processing-${argv.key}.json`
  let nextProcessingFrom: string | null = null

  if (fs.existsSync(savePath)) {
    const nextProcessing = JSON.parse(fs.readFileSync(savePath, { encoding: 'utf-8' }))
    nextProcessingFrom = nextProcessing.nextProcessingFrom
  }

  const results = await search(argv.type, nextProcessingFrom)
  if (!results.length) return

  for (let index = 0; index < results.length; index++) {
    const currentResult = results[index]
    const metricValue = getNestedValue(currentResult, argv.key);
    if (metricValue === undefined) {
        console.warn(`Skipping record _id: ${currentResult._id}: Key ${argv.key} does not exist or is not a number`);
        continue;
    }
    if (currentResult.data.alert !== undefined) continue

    const latestResults = results.slice(Math.max(0, index - 10), index)
    if (!latestResults.length) continue

    const validValues = latestResults.map((x) => getNestedValue(x, argv.key)).filter((v): v is number => v !== undefined);
    if (!validValues.length) {
        console.warn(`No valid values for average calculation at record _id: ${currentResult._id}`);
        continue;
    }
    const total = sum(validValues)
    const average = total / validValues.length
    const alert: number = metricValue > average ? 1 : 0
    const data: UpdateData = { data: { alert: alert } }
    await update(currentResult._id, data)
  }

  const saveTimestamp: string = results[Math.max(0, results.length - 10)].timestamp
  const saveObj = { nextProcessingFrom: saveTimestamp }

  if (!fs.existsSync(process.env.NEXT_PROCESSING_FOLDER!)) {
    fs.mkdirSync(process.env.NEXT_PROCESSING_FOLDER!, { recursive: true })
  }
  fs.writeFileSync(savePath, JSON.stringify(saveObj))
}

if (argv.daemon) {
  if (argv.interval) {
    cron.schedule(argv.interval, () => doMain())
  } else {
    throw new Error('When cron is started, interval argument is required.')
  }
} else {
  doMain()
}
