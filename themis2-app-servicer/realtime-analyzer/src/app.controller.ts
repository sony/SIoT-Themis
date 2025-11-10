import { BadRequestException, Body, Controller, Post } from '@nestjs/common'
type SensorData = {
  data: {
    sos?: number
  }
}

type AnalyzedData = {
  data: {
    alert?: number
  }
}

@Controller('realtime-analyzer')
export class AppController {
  @Post()
  postRequestBody(@Body() body: SensorData): AnalyzedData {
    if (body.data.sos == null) {
      throw new BadRequestException('Invalid request format')
    } else if (body.data.sos) {
      return { data: { alert: 1 } }
    } else {
      return { data: { alert: 0 } }
    }
  }
}
