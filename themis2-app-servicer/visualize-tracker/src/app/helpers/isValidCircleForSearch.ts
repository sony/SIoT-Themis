const maxRadius = Number(process.env.NEXT_PUBLIC_SEARCH_CIRCLE_MAX_RADIUS!)

export const isValidLatitude = (latitude: string) => {
  if (!latitude || Number.isNaN(Number(latitude)) || !(Number(latitude) >= -85 && Number(latitude) <= 85)) {
    return false
  }
  return true
}

export const isValidLongitude = (longitude: string) => {
  if (!longitude || Number.isNaN(Number(longitude)) || !(Number(longitude) >= -180 && Number(longitude) <= 180)) {
    return false
  }
  return true
}

export const isValidKilometerRadius = (radius: string) => {
  if (!radius || Number.isNaN(Number(radius)) || !(Number(radius) >= 1 && Number(radius) <= maxRadius)) {
    return false
  }
  return true
}
