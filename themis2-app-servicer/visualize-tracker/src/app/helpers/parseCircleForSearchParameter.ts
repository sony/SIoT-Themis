import { getParameter } from './getParameter'

import type { CircleForSearch } from '@/app/types/circle'

import { isValidLatitude, isValidLongitude, isValidKilometerRadius } from '@/app/helpers/isValidCircleForSearch'

export const parseCircleForSearchParameter = (
  searchParams: URLSearchParams | null,
  extraction: boolean,
): CircleForSearch => {
  const parsed: CircleForSearch = { latitude: '', longitude: '', radius: '' }

  if (!searchParams) return parsed

  const latitude = getParameter(searchParams, 'latitude', extraction)
  const longitude = getParameter(searchParams, 'longitude', extraction)
  if (latitude && isValidLatitude(latitude)) parsed.latitude = latitude
  if (longitude && isValidLongitude(longitude)) parsed.longitude = longitude

  const radius = getParameter(searchParams, 'radius', extraction)
  if (!radius || Number.isNaN(Number(radius))) return parsed
  const kilometerRadius = (Number(radius) / 1000).toString()
  if (isValidKilometerRadius(kilometerRadius)) parsed.radius = kilometerRadius

  return parsed
}
