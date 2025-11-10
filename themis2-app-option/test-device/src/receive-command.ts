import * as fs from 'fs'

import { mqtt5, iot } from 'aws-iot-device-sdk-v2'
import * as urlsafeBase64 from 'urlsafe-base64'
import * as yargs from 'yargs'

interface DeviceConfig {
  deviceName: string
  subscribeTopics: string[]
  apiKey: string
}

interface MqttConfig {
  endpoint: string
  certificatePath: string
  keyPath: string
  caPath: string
  port: string
}

type Definition = {
  offset: number
  length: number
  gain?: number
  bias?: number
}

const defaultTemplate =
  process.argv.includes('--binary') || process.argv.includes('-b') ? 'templates/binary.json' : 'templates/eltres.json'

const argv = yargs
  .option('data', {
    type: 'string',
    description:
      'Data to be passed to the test sensor. If it is an object, a single piece of data is sent; If it is an array, the data is sent in sequence. (JSON format)',
    demandOption: true,
  })
  .option('topic', {
    type: 'string',
    description: 'Specify the mqtt topic name.',
    demandOption: true,
  })
  .option('interval', {
    type: 'number',
    description: 'Interval for sending test data. (seconds)',
    demandOption: false,
    default: 60,
  })
  .option('loop', {
    type: 'boolean',
    description: 'Repeatedly send test data.',
    demandOption: false,
    default: false,
  })
  .option('template', {
    type: 'string',
    description: 'Specify the format of test data to be sent to AWS IoT Core. (file path)',
    demandOption: false,
    default: defaultTemplate,
  })
  .option('definitions', {
    type: 'string',
    description: 'Specify the mapping definition to create the dataPayload. (file path)',
    demandOption: false,
    default: 'mapping-assignment.json',
  })
  .option('config', {
    type: 'string',
    description: 'Specify the configuration file to connect to the MQTT broker. (file path)',
    demandOption: false,
    default: 'mqtt-config.json',
  })
  .option('deviceConfig', {
    type: 'string',
    description: 'Path to device config file',
    demandOption: false,
    default: 'device-config.json',
  })
  .option('eltres', {
    type: 'boolean',
    description: 'Enable ELTRES mode.',
    default: false,
  })
  .option('binary', {
    type: 'string',
    description: 'Binary file path to encode to base64url',
    demandOption: false,
    default: '',
  })
  .parseSync()

const template = JSON.parse(fs.readFileSync(argv.template, 'utf-8'))
const settings: DeviceConfig = JSON.parse(fs.readFileSync(argv.deviceConfig, 'utf-8'))
const config: MqttConfig = JSON.parse(fs.readFileSync(argv.config, 'utf-8'))
const hasBinary = argv.binary && fs.existsSync(argv.binary)
const definitions: Record<string, Definition> = JSON.parse(fs.readFileSync(argv.definitions, 'utf-8'))

if (argv.eltres && hasBinary) {
  console.error('Error: Cannot use --eltres and --binary together')
  process.exit(1)
}

const mqttConfig = iot.AwsIotMqtt5ClientConfigBuilder.newDirectMqttBuilderWithMtlsFromPath(
  config.endpoint,
  config.certificatePath,
  config.keyPath,
)
  .withCertificateAuthorityFromPath(undefined, config.caPath)
  .withPort(parseInt(config.port, 10))
  .build()
const client: mqtt5.Mqtt5Client = new mqtt5.Mqtt5Client(mqttConfig)

let isSending = false
let lastCommand: string | null = null
const publishTopic = `/${settings.apiKey}/${settings.deviceName}/cmdexe`
const subscribeTopic = `/${settings.apiKey}/${settings.deviceName}/cmd`

client.on('connectionSuccess', () => {
  console.log('Connected to AWS IoT')
  console.log(`Publish topic for command execution results: ${publishTopic}`)
  const subscriptions = [
    {
      topicFilter: subscribeTopic,
      qos: mqtt5.QoS.AtLeastOnce,
    },
  ]
  client
    .subscribe({ subscriptions })
    .then(() => console.log(`Subscribed to topic: ${subscribeTopic}`))
    .catch((err) => console.error('Failed to subscribe:', err))
})

if (argv.loop) {
  isSending = true
  doMain()
}

client.on('messageReceived', async (eventData: mqtt5.MessageReceivedEvent) => {
  try {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    let payload: { 'send-data'?: string } = {}
    if (eventData.message.payload) {
      try {
        if (typeof eventData.message.payload === 'string') {
          payload = JSON.parse(eventData.message.payload)
        } else if (eventData.message.payload instanceof ArrayBuffer || Buffer.isBuffer(eventData.message.payload)) {
          payload = JSON.parse(Buffer.from(eventData.message.payload).toString('utf8'))
        } else {
          // eslint-disable-next-line @typescript-eslint/naming-convention
          payload = eventData.message.payload as { 'send-data'?: string }
        }
        if (typeof payload !== 'object' || payload === null) {
          console.error('Invalid payload: not an object', payload)
          return
        }
      } catch (error) {
        console.error('Failed to parse payload:', error)
        return
      }
    }
    console.log(`Received message on topic ${eventData.message.topicName}:`, payload)

    if (payload['send-data'] === 'on') {
      if (lastCommand === 'on') {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        await sendResponse(publishTopic, { 'send-data': 'already on' })
        return
      }
      lastCommand = 'on'
      try {
        if (!isSending) {
          isSending = true
          doMain()
          // eslint-disable-next-line @typescript-eslint/naming-convention
          await sendResponse(publishTopic, { 'send-data': 'on success' })
        } else {
          console.log('Already sending data')
          // eslint-disable-next-line @typescript-eslint/naming-convention
          await sendResponse(publishTopic, { 'send-data': 'on success' })
        }
      } catch (error) {
        console.error('Error starting send:', error)
        // eslint-disable-next-line @typescript-eslint/naming-convention
        await sendResponse(publishTopic, { 'send-data': 'on failure' })
      }
    } else if (payload['send-data'] === 'off') {
      if (lastCommand === 'off') {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        await sendResponse(publishTopic, { 'send-data': 'already off' })
        return
      }
      lastCommand = 'off'
      try {
        if (isSending) {
          isSending = false
          // eslint-disable-next-line @typescript-eslint/naming-convention
          await sendResponse(publishTopic, { 'send-data': 'off success' })
        } else {
          console.log('No data to stop')
          // eslint-disable-next-line @typescript-eslint/naming-convention
          await sendResponse(publishTopic, { 'send-data': 'off success' })
        }
      } catch (error) {
        console.error('Error stopping send:', error)
        // eslint-disable-next-line @typescript-eslint/naming-convention
        await sendResponse(publishTopic, { 'send-data': 'off failure' })
      }
    }
  } catch (error) {
    console.error('Error processing message:', error)
  }
})

client.on('connectionFailure', (eventData: mqtt5.ConnectionFailureEvent) => {
  console.error('Connection failure event:', eventData.error.toString())
  if (eventData.connack) {
    console.error('Connack:', JSON.stringify(eventData.connack))
  }
})

client.on('disconnection', (eventData: mqtt5.DisconnectionEvent) => {
  console.error('Disconnection event:', eventData.error.toString())
  if (eventData.disconnect) {
    console.error('Disconnect packet:', JSON.stringify(eventData.disconnect))
  }
})

client.on('stopped', () => {
  console.log('Stopped event')
})

client.on('error', (error) => {
  console.error('Error event:', error.toString())
})

process.on('SIGINT', () => {
  isSending = false
  console.log('Stopping due to Ctrl+C...')
  client.stop()
  setTimeout(() => {
    console.log('Timeout waiting for client stop, forcing exit')
    process.exit(0)
  }, 5000)
})

async function doMain() {
  let data
  try {
    data = JSON.parse(argv.data)
    console.log(`Parsed data: ${JSON.stringify(data)}`)
  } catch (e) {
    console.error('Invalid JSON data:', e)
    isSending = false
    return
  }
  const values = Array.isArray(data) ? data : [data]
  console.log(`Values to send: ${values.length} items`)

  while (isSending) {
    for (const value of values) {
      if (!isSending) break
      try {
        await sendAwsIotCore(client, value)
        if (hasBinary) {
          const templateBinary = makeBase64urlPayload(value)
          console.info(`${new Date().toISOString()} send data : ${JSON.stringify(templateBinary)}`)
        } else {
          if (argv.eltres) {
            console.info(`${new Date().toISOString()} send data : ${JSON.stringify(template)}`)
          } else {
            console.info(`${new Date().toISOString()} send data : ${JSON.stringify(value)}`)
          }
        }
      } catch (error) {
        console.error(error)
      }
      if (isSending) {
        await sleep(argv.interval * 1000)
      }
    }
    if (!argv.loop) break
  }
}

// eslint-disable-next-line @typescript-eslint/naming-convention
async function sendResponse(topic: string, response: { 'send-data': string }) {
  try {
    await client.publish({
      qos: mqtt5.QoS.AtLeastOnce,
      topicName: topic,
      payload: JSON.stringify(response),
    })
    console.log(`Sent response to ${topic}:`, response)
  } catch (error) {
    console.error(`Error sending response to ${topic}:`, error)
  }
}

function getBase64UrlFromBinaryFile(filePath: string): string {
  try {
    const binaryData = fs.readFileSync(filePath)
    return urlsafeBase64.encode(binaryData)
  } catch (error) {
    console.error(`Error reading or encoding binary file ${filePath}`, error)
    return ''
  }
}

function makeBase64urlPayload(data: Record<string, number | undefined>): unknown {
  try {
    console.log('Data to genarate', data)
    const templateCopy = JSON.parse(JSON.stringify(template))
    const base64UrlBinary = getBase64UrlFromBinaryFile(argv.binary)
    if (!base64UrlBinary && hasBinary) {
      console.error('Unable to create base64url data')
    }
    templateCopy.snapshot.metadata.timestamp.value = new Date().toISOString()
    templateCopy.snapshot.value = base64UrlBinary || ''
    if (hasBinary) {
      const fileStats = fs.statSync(argv.binary)
      templateCopy.snapshot.metadata.size.value = fileStats.size
    } else {
      templateCopy.snapshot.metadata.size.value = 0
    }
    return templateCopy
  } catch (error) {
    console.log('Error generating payload', error)
    return
  }
}

async function sendAwsIotCore(mqttClient: mqtt5.Mqtt5Client, value: Record<string, number | undefined>) {
  try {
    let payload: string
    if (hasBinary) {
      const templateBinary = makeBase64urlPayload(value)
      payload = JSON.stringify(templateBinary)
    } else {
      if (argv.eltres) {
        template.txTime = new Date().getTime() / 1000
        template.dataPayload = makeEltresPayload(value)
        payload = JSON.stringify(template)
      } else {
        payload = JSON.stringify(value)
      }
    }
    await mqttClient.publish({
      qos: mqtt5.QoS.AtLeastOnce,
      topicName: argv.topic,
      payload,
    })
  } catch (error) {
    console.error('Error', error)
  }
}

function makeEltresPayload(data: Record<string, number | undefined>): string {
  const binaryDigits = Array(128).fill(0)

  Object.entries(definitions).forEach(([field, definition]) => {
    if (definition.gain === 0) throw new Error('0 cannot be used for gain in the mapping definition.')
    const value = data[field] ?? 0
    const gain = definition.gain ?? 1
    const bias = definition.bias ?? 0
    const rawValue = Math.round((value - bias) / gain)
    const offset = definition.offset
    const length = definition.length
    const binaryPart = rawValue.toString(2).slice(-length).padStart(length, '0')
    binaryDigits.splice(offset, length, ...binaryPart.split(''))
  })

  const binaryString: string = binaryDigits.join('')

  let hexString: string = ''
  binaryString.match(/.{4}/g)?.forEach((chunk) => {
    hexString += parseInt(chunk, 2).toString(16)
  })
  return hexString
}

async function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function main() {
  client.start()
}

main()
