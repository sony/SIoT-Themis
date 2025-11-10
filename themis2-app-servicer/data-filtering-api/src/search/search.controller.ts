import { Controller, Get, Headers, Query, UnauthorizedException, BadRequestException } from '@nestjs/common'

import { SearchQueryDto } from './dto/search-query.dto'
import { SearchService } from './search.service'

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}
  @Get()
  async search(@Headers('Authorization') authorization: string, @Query() query: SearchQueryDto): Promise<unknown> {
    if (!authorization) {
      throw new UnauthorizedException('Authorization header is required')
    }
    if (Object.keys(query).length === 0) {
      throw new BadRequestException('Type does not exist')
    }
    return await this.searchService.search(query, authorization)
  }
}
