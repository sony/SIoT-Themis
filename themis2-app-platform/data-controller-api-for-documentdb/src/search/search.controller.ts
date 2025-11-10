import { Controller, Get, Headers, Query, ValidationPipe } from '@nestjs/common'

import { SearchQueryDto } from './dto/search-query.dto'
import { SearchService } from './search.service'

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  async search(
    @Headers('collection') collection: string,
    @Query(
      new ValidationPipe({
        transform: true,
        transformOptions: { enableImplicitConversion: true },
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    )
    query: SearchQueryDto,
  ): Promise<unknown> {
    return await this.searchService.search(
      collection,
      query.type,
      query.q,
      query.geoattr,
      query.georel,
      query.geometry,
      query.coords,
      query.limit,
    )
  }
}
