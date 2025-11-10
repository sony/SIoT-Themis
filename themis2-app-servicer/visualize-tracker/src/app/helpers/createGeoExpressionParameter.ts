import type { GeoExpression } from '@/app/types/circle'

import { isValidLatitude, isValidLongitude, isValidKilometerRadius } from '@/app/helpers/isValidCircleForSearch'

export const createGeoExpressionParameter = (geoExpression: GeoExpression) => {
  const latitude = geoExpression.coodsLatitude
  const longitude = geoExpression.coodsLongitude
  const radius = geoExpression.maxDistance

  if (!isValidLatitude(latitude)) return []
  if (!isValidLongitude(longitude)) return []
  if (!isValidKilometerRadius(radius)) return []

  const geoExpressionParams: [key: 'georel' | 'coords', value: string][] = []

  const meterRadius = Number(radius) * 1000
  geoExpressionParams.push(['georel', `near;maxDistance:${meterRadius}`], ['coords', `${latitude},${longitude}`])

  return geoExpressionParams
}
