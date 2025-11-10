import { getParameter } from './getParameter'

import type { GeoExpression } from '@/app/types/circle'

import { isValidLatitude, isValidLongitude, isValidKilometerRadius } from '@/app/helpers/isValidCircleForSearch'

export const parseGeoExpressionParameter = (
  searchParams: URLSearchParams | null,
  extraction: boolean,
): GeoExpression => {
  const defaultSearchParam: GeoExpression = { coodsLatitude: '', coodsLongitude: '', maxDistance: '' }
  if (!searchParams) return defaultSearchParam

  const georel = getParameter(searchParams, 'georel', extraction)
  const coords = getParameter(searchParams, 'coords', extraction)
  if (!georel || !coords) return defaultSearchParam

  const regexp = new RegExp(`(.+),(.+)`)
  const match = coords.match(regexp)
  if (!match) return defaultSearchParam

  const [, coodsLatitude, coodsLongitude] = match
  if (!isValidLatitude(coodsLatitude)) return defaultSearchParam
  if (!isValidLongitude(coodsLongitude)) return defaultSearchParam

  if (!georel.startsWith('near;maxDistance:')) return defaultSearchParam

  const radius = georel.replace('near;maxDistance:', '')
  if (Number.isNaN(Number(radius))) return defaultSearchParam

  const kilometerRadius = (Number(radius) / 1000).toString()
  if (!isValidKilometerRadius(kilometerRadius)) return defaultSearchParam

  return {
    coodsLatitude,
    coodsLongitude,
    maxDistance: kilometerRadius,
  }
}
