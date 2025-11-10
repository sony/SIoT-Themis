export function generateCirclePolygonPoints(
  center: { lat: number; lng: number },
  radiusInMeters: number,
  segments = 64,
): google.maps.LatLngLiteral[] {
  const points: google.maps.LatLngLiteral[] = []
  const earthRadius = 6378137

  const lat = (center.lat * Math.PI) / 180
  const lng = (center.lng * Math.PI) / 180
  const d = radiusInMeters / earthRadius

  for (let i = 0; i <= segments; i++) {
    const theta = (2 * Math.PI * i) / segments
    const latOffset = Math.asin(Math.sin(lat) * Math.cos(d) + Math.cos(lat) * Math.sin(d) * Math.cos(theta))
    const lngOffset =
      lng + Math.atan2(Math.sin(theta) * Math.sin(d) * Math.cos(lat), Math.cos(d) - Math.sin(lat) * Math.sin(latOffset))

    points.push({
      lat: (latOffset * 180) / Math.PI,
      lng: (lngOffset * 180) / Math.PI,
    })
  }

  return points
}
