import { BadRequestException, Injectable, UnprocessableEntityException } from '@nestjs/common'
import { point } from '@turf/helpers'
import { circle } from '@turf/turf'

import { DocumentDBService } from '../providers/documentdb.service'

import { SearchResult, SearchRawResult } from './types/searchResult'

type ComparisonFilter = {
  $gte?: Date | number | string
  $lte?: Date | number | string
  $gt?: Date | number | string
  $lt?: Date | number | string
  $eq?: Date | number | string
}

type QueryFilter = { [key: string]: ComparisonFilter }[]

type ParsedGeorel = {
  type: string
  attributes: Record<string, string>
}

type Coordinates = [number, number]

type GeoWithinFilter = {
  $geoWithin: {
    $geometry: {
      type: string
      coordinates: Coordinates[]
    }
  }
}

type NearFilter = {
  $near: {
    $geometry: {
      type: string
      coordinates: Coordinates
    }
    $maxDistance?: number
  }
}

type LocationFilter = GeoWithinFilter | NearFilter

type Filter = {
  entityType: string
  $and?: QueryFilter
  location?: LocationFilter
}

@Injectable()
export class SearchService {
  constructor(private readonly documentdb: DocumentDBService) {}

  async search(
    collection: string,
    entityType: string,
    query?: string,
    geoattr?: string,
    georel?: string,
    geometry?: string,
    coords?: string,
    limit?: number,
  ): Promise<SearchResult[]> {
    try {
      if (geometry === 'point') {
        const match = georel?.match(/maxDistance:(\d+)/)
        if (!match) throw new BadRequestException()
        const radius = Number(match[1])
        if (!radius || !coords) throw new BadRequestException()
        if (radius > 10000000) {
          geoattr = undefined
          georel = undefined
          geometry = undefined
          coords = undefined
        } else {
          const generatedPolygon = generatePseudoCirclePolygon(radius, coords)
          geometry = 'polygon'
          georel = 'coveredBy'
          coords = generatedPolygon
        }
      }

      let dbQuery = this.documentdb
        .getCollection('sth_' + collection.replace(/\//g, 'x002f'))
        .find(buildFilter(entityType, query, geoattr, georel, geometry, coords))
        .sort({ timestamp: -1 })

      if (limit) {
        dbQuery = dbQuery.limit(limit)
      }

      const results = ((await dbQuery.toArray()) as unknown as SearchRawResult[]).map(
        ({ _id: rawId, entityId, entityType, ...rest }) => {
          return {
            ...rest,
            _id: rawId.toString(),
            id: entityId,
            type: entityType,
          }
        },
      ) as SearchResult[]
      return results
    } catch (error) {
      throw new UnprocessableEntityException({
        error: 'NotSupportedQuery',
        message: 'Invalid query or geospatial data',
        detail: error.toString(),
      })
    }
  }
}

function buildFilter(
  entityType: string,
  query?: string,
  geoattr?: string,
  georel?: string,
  geometry?: string,
  coords?: string,
): Filter {
  const queryFilter = buildQueryFilter(query)
  const locationFilter = buildLocationFilter(geoattr, georel, geometry, coords)

  return {
    entityType,
    ...queryFilter,
    ...locationFilter,
  }
}

function buildQueryFilter(query?: string): Partial<Filter> {
  if (!query) return {}

  const filterList: QueryFilter = []

  query.split(';').forEach((condition) => {
    const match = condition.match(/(?<key>[a-zA-Z0-9.]+)(?<operator>[><]=?|==)(?<value>.+)/)
    if (!match?.groups) return

    const { key, operator, value } = match.groups
    const comparisonFilter: ComparisonFilter = {}
    const convertedValue = convertValue(key, value)
    switch (operator) {
      case '<':
        comparisonFilter.$lt = convertedValue
        break
      case '<=':
        comparisonFilter.$lte = convertedValue
        break
      case '>':
        comparisonFilter.$gt = convertedValue
        break
      case '>=':
        comparisonFilter.$gte = convertedValue
        break
      case '==':
        comparisonFilter.$eq = convertedValue
        break
    }

    filterList.push({ [key]: comparisonFilter })
  })
  return { $and: [...filterList] }
}

function buildLocationFilter(geoattr?: string, georel?: string, geometry?: string, coords?: string): Partial<Filter> {
  if (!geoattr || !geometry || !georel || !coords) return {}

  const parsedGeorel = parseGeorel(georel)
  const coordinates = convertToCoordinateArray(coords)
  let locationFilter: LocationFilter

  switch (parsedGeorel.type) {
    case 'coveredBy':
      locationFilter = {
        $geoWithin: {
          $geometry: {
            type: geometry.charAt(0).toUpperCase() + geometry.slice(1),
            coordinates: [coordinates] as Coordinates[],
          },
        },
      }
      break
    case 'near':
      const maxDistance = parseFloat(parsedGeorel.attributes.maxDistance)
      if (isNaN(maxDistance)) {
        throw new Error('maxDistance attribute does not exist')
      }

      locationFilter = {
        $near: {
          $geometry: {
            type: geometry.charAt(0).toUpperCase() + geometry.slice(1),
            coordinates: coordinates as Coordinates,
          },
          ...(maxDistance !== undefined ? { $maxDistance: maxDistance } : {}),
        },
      }
      break
    default:
      throw new Error(`Unsupported type (${parsedGeorel.type}) in georel`)
  }

  return { location: locationFilter }
}

function convertValue(key: string, value: string): Date | number | string {
  if (key === 'timestamp') return new Date(value)

  if (value.startsWith("'") && value.endsWith("'")) {
    return value.slice(1, -1)
  }

  const num = Number(value)
  return isNaN(num) ? value : num
}

function parseGeorel(georel: string): ParsedGeorel {
  const [type, ...attributes] = georel.split(';')
  const attributeMap = Object.fromEntries(attributes.map((attribute) => attribute.split(':')))

  return { type: type, attributes: attributeMap }
}

function convertToCoordinateArray(coordsString: string): Coordinates | Coordinates[] {
  const coordsArray = coordsString.split(';').map((coord) => {
    const [latitude, longitude] = coord.split(',').map(Number)
    return [longitude, latitude] as Coordinates
  })

  return coordsArray.length === 1 ? coordsArray[0] : coordsArray
}

function generatePseudoCirclePolygon(radius: number, coords: string) {
  const parsedCoords: number[] = coords.split(',').map((str) => {
    const num = Number(str)
    if (isNaN(num)) throw new BadRequestException()
    return num
  })
  const parsedPoint = point([parsedCoords[1], parsedCoords[0]])
  const options = {
    steps: 64,
    units: 'meters' as const,
  }
  const circles = circle(parsedPoint, radius ? radius : 0, options)
  coords = circles.geometry.coordinates[0]
    .map(([lng, lat]: [number, number]) => {
      lng = ((((lng + 180) % 360) + 360) % 360) - 180
      return `${lat},${lng}`
    })
    .join(';')
  return coords
}
