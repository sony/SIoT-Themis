import { Body, Controller, HttpCode, Param, Post } from '@nestjs/common'

import { AppService } from './app.service'
import { BodyDto } from './dto/body-dto'
import { ParamDto } from './dto/param-dto'

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Post('/:token')
  @HttpCode(204)
  sendDataToGrafana(@Body() body: BodyDto, @Param() param: ParamDto) {
    const lineProtocolConvertedData: string = this.appService.convertToLineProtocol(body)
    // Send data to Grafana if lineProtocolCovertedData exists
    if (lineProtocolConvertedData) {
      this.appService.sendDataToGrafana(lineProtocolConvertedData, param.token)
    }
  }
}
