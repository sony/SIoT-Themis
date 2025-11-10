import * as fs from 'fs'

import { mqtt5, iot } from 'aws-iot-device-sdk-v2'
import * as urlsafeBase64 from 'urlsafe-base64'
import * as yargs from 'yargs'

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
    description: 'Specify the configuration file to connect to the MQTT broker.. (file path)',
    demandOption: false,
    default: 'mqtt-config.json',
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
const definitions: Record<string, Definition> = JSON.parse(fs.readFileSync(argv.definitions, 'utf-8'))
const config = JSON.parse(fs.readFileSync(argv.config, 'utf-8'))
const hasBinary = argv.binary && fs.existsSync(argv.binary)

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

client.on('connectionFailure', (eventData: mqtt5.ConnectionFailureEvent) => {
  console.error('Connection failure event: ' + eventData.error.toString())
  if (eventData.connack) {
    console.error('Connack: ' + JSON.stringify(eventData.connack))
  }
})
client.start()

async function doMain() {
  const data = JSON.parse(argv.data)
  const values = Array.isArray(data) ? data : [data]

  while (true) {
    for (const value of values) {
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
      await sleep(argv.interval * 1000)
    }
    if (!argv.loop) break
  }
  client.close()
}

doMain()

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
    const template = JSON.parse(fs.readFileSync(argv.template, 'utf-8'))
    const base64UrlBinary = getBase64UrlFromBinaryFile(argv.binary)
    if (!base64UrlBinary) {
      console.error('Unable to create base64url data')
    }
    template.snapshot.metadata.timestamp.value = new Date().toISOString()
    template.snapshot.value = base64UrlBinary
    return template
  } catch (error) {
    console.log('Error generating payload', error)
    return
  }
}
