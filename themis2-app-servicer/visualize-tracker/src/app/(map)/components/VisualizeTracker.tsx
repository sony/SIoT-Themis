'use client'
import { Error } from '@mui/icons-material'
import { Box } from '@mui/material'
import { AdvancedMarker, APIProvider, Map, Pin } from '@vis.gl/react-google-maps'
import { useSearchParams } from 'next/navigation'
import { useTranslations } from 'next-intl'
import React, { useCallback, useContext, useEffect, useState } from 'react'

import { Polygon } from './polygon'

import type { GeoExpression } from '@/app/types/circle'
import type { ConditionClause } from '@/app/types/condition'
import type { ServerActionResponse } from '@/app/types/serverActionResponse'
import type { Ship } from '@/app/types/ship'

import { Circle } from '@/app/(map)/components/circle'
import { Loading } from '@/app/(map)/components/Loading'
import { Polyline } from '@/app/(map)/components/polyline'
import { ReplayController } from '@/app/(map)/components/ReplayController'
import { createNotification, deleteNotification } from '@/app/actions/notify'
import { search } from '@/app/actions/search'
import { getParameter } from '@/app/helpers/getParameter'
import { parseCircleForSearchParameter } from '@/app/helpers/parseCircleForSearchParameter'
import { parseDisplayParameter } from '@/app/helpers/parseDisplayParameter'
import { parseGeoExpressionParameter } from '@/app/helpers/parseGeoExpressionParameter'
import { parseKeyValueFilterQuery } from '@/app/helpers/parseKeyValueFilterQuery'
import { parseTimeFilterQuery } from '@/app/helpers/parseTimeFilterQuery'
import { SnackbarContext } from '@/app/SnackbarProvider'
import { socket } from '@/app/socket'
import metrics from '@/data/metrics.json'
import { generateCirclePolygonPoints } from '@/lib/geo/generateCirclePolygon'

const dataType = process.env.NEXT_PUBLIC_DATA_TYPE!

type LocatedShip = Ship & Required<Pick<Ship, 'location'>>

type ReplayTimeRange = {
  start: Date
  end: Date
}

function valueByPath(obj: Ship, path: string): string | undefined {
  let o: unknown = obj
  for (const key of path.split('.')) {
    if (!o || typeof o !== 'object' || !(key in o)) return undefined
    o = (o as Record<string, unknown>)[key]
  }
  if (typeof o === 'object') return JSON.stringify(o)
  return o?.toString()
}

function groupShips(ships: Ship[]): Record<string, LocatedShip[]> {
  const locatedShips = ships.filter(
    (ship) => ship.location?.coordinates[0] != null && ship.location?.coordinates[1] != null,
  ) as LocatedShip[]
  return locatedShips.reduce<Record<string, LocatedShip[]>>((groupedShips, ship) => {
    if (!groupedShips[ship.id]) {
      groupedShips[ship.id] = []
    }
    groupedShips[ship.id].push(ship)
    return groupedShips
  }, {})
}

function mergeGroupedShips(
  input: Record<string, LocatedShip[]>,
  target: Record<string, LocatedShip[]>,
  limitByGroup?: number,
): Record<string, LocatedShip[]> {
  const allIds = Array.from(new Set(Object.keys(target).concat(Object.keys(input))))
  return allIds.reduce<Record<string, LocatedShip[]>>((merged, id) => {
    let group = (target[id] || [])
      .concat(input[id] || [])
      .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
    if (limitByGroup && group.length >= limitByGroup) {
      group = group.slice(-limitByGroup)
    }
    merged[id] = group
    return merged
  }, {})
}

async function searchShips(
  realtime: boolean,
  query: string | undefined,
  geoExpression: GeoExpression,
  noRedundantParameter: boolean,
): Promise<ServerActionResponse<Ship[]> | undefined> {
  let filterClauses: ConditionClause[] = []
  const noGeoExpression = !geoExpression.coodsLatitude && !geoExpression.coodsLongitude && !geoExpression.maxDistance

  if (realtime) {
    const toDate = new Date()
    const fromDate = new Date(toDate.getTime() - 15 * 60 * 1000)
    filterClauses.push(
      { field: 'timestamp', operator: '>=', value: fromDate.toISOString() },
      { field: 'timestamp', operator: '<=', value: toDate.toISOString() },
    )
    if (query) filterClauses = [...filterClauses, ...parseKeyValueFilterQuery(query)]
  } else if (!query && noGeoExpression && noRedundantParameter) {
    const toDate = new Date()
    const fromDate = new Date(toDate.getTime() - 10 * 60 * 1000)
    filterClauses.push(
      { field: 'timestamp', operator: '>=', value: fromDate.toISOString() },
      { field: 'timestamp', operator: '<=', value: toDate.toISOString() },
    )
  } else if (query) {
    filterClauses = [...parseTimeFilterQuery(query), ...parseKeyValueFilterQuery(query)]
  }

  if (filterClauses.length === 0 && noGeoExpression) return undefined

  return await search(dataType, filterClauses, geoExpression)
}

function minAndMaxTimes(groupedShips: Record<string, LocatedShip[]>): { min: Date; max: Date } | undefined {
  let min: Date | undefined = undefined
  let max: Date | undefined = undefined
  Object.keys(groupedShips).forEach((id) => {
    const shipGroup = groupedShips[id]

    const firstTimestamp = new Date(shipGroup[0].timestamp)
    const lastTimestamp = new Date(shipGroup[shipGroup.length - 1].timestamp)

    min = min ? new Date(Math.min(min.getTime(), firstTimestamp.getTime())) : firstTimestamp
    max = max ? new Date(Math.max(max.getTime(), lastTimestamp.getTime())) : lastTimestamp
  })
  if (!min || !max) return undefined
  return { min, max }
}

function getReplayTimeRange(
  query: string | undefined,
  groupedShips: Record<string, LocatedShip[]>,
): ReplayTimeRange | undefined {
  if (!query) return undefined

  const minAndMax = minAndMaxTimes(groupedShips)
  if (!minAndMax) return undefined

  let start: Date | undefined = undefined
  let end: Date | undefined = undefined
  parseTimeFilterQuery(query).forEach((condition: ConditionClause) => {
    if (condition.operator === '>=') {
      start = new Date(condition.value)
    } else if (condition.operator === '<=') {
      end = new Date(condition.value)
    }
  })
  if (start && end) return { start, end }

  start ||= minAndMax.min
  end ||= minAndMax.max
  return { start, end }
}

export function VisualizeTracker() {
  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_JAVASCRIPT_API_KEY as string
  const realtimeShipCountLimit = Number(process.env.NEXT_PUBLIC_REALTIME_SHIP_COUNT_LIMIT) || 5
  const { setAlert } = useContext(SnackbarContext)
  const readOnlySearchParams = useSearchParams()
  const searchParams = readOnlySearchParams ? new URLSearchParams(readOnlySearchParams) : new URLSearchParams()
  const { showDataSource, dataSource, color, opacity } = parseDisplayParameter(searchParams, true)
  const gain = metrics.find((metric) => metric.field === dataSource)?.gain ?? 0
  const realtime = getParameter(searchParams, 'realtime', true) === 'true'
  const query = getParameter(searchParams, 'q', true)
  const searchTime = getParameter(searchParams, 'searchTime', true)
  const { latitude, longitude, radius } = parseCircleForSearchParameter(searchParams, true)
  const { coodsLatitude, coodsLongitude, maxDistance } = parseGeoExpressionParameter(searchParams, true)
  const noRedundantParameter = Array.from(searchParams.keys()).length === 0

  // The default location is set to Tokyo Station.
  const [centerLocation, setCenterLocation] = useState<google.maps.LatLngLiteral>({ lat: 35.681236, lng: 139.767125 })
  const [isLoading, setIsLoading] = useState(true)
  const [groupedShips, setGroupedShips] = useState<Record<string, LocatedShip[]>>({})
  const [isReplaying, setIsReplaying] = useState(false)
  const [replaySpeedMultiplier, setReplaySpeedMultiplier] = useState(1)
  const [replayTimeRange, setReplayTimeRange] = useState<ReplayTimeRange | undefined>(undefined)
  const [replayCurrentTime, setReplayCurrentTime] = useState<Date | undefined>(undefined)
  const t = useTranslations('VisualizeTracker')

  const setCurrentLocation = useCallback(() => {
    navigator.geolocation.getCurrentPosition(
      (position: GeolocationPosition) => {
        const currentLocation: google.maps.LatLngLiteral = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        }
        setCenterLocation(currentLocation)
        setIsLoading(false)
      },
      () => {
        setAlert({ severity: 'warning', message: t('currentLocationAcquisitionFailed') })
        setIsLoading(false)
      },
    )
  }, [setAlert, t])

  const resetReplay = useCallback(() => {
    setIsReplaying(false)
    setReplayTimeRange(undefined)
    setReplayCurrentTime(undefined)
  }, [setIsReplaying, setReplayTimeRange, setReplayCurrentTime])

  useEffect(() => {
    setCurrentLocation()
  }, [setCurrentLocation])

  useEffect(() => {
    resetReplay()
    ;(async () => {
      const geoExpression: GeoExpression = {
        coodsLatitude,
        coodsLongitude,
        maxDistance,
      }
      const response = await searchShips(realtime, query, geoExpression, noRedundantParameter)
      if (!response) return

      if (!response.success) {
        setAlert({ severity: 'error', message: response.errors.name })
        return
      }

      const groupedShips = mergeGroupedShips(
        groupShips(response.data),
        {},
        realtime ? realtimeShipCountLimit : undefined,
      )
      setGroupedShips(groupedShips)

      setIsReplaying(false)
      setReplayTimeRange(getReplayTimeRange(query, groupedShips))
      setReplayCurrentTime(undefined)
    })()
  }, [
    query,
    realtime,
    noRedundantParameter,
    realtimeShipCountLimit,
    setAlert,
    resetReplay,
    searchTime,
    coodsLatitude,
    coodsLongitude,
    maxDistance,
  ])

  useEffect(() => {
    if (!realtime) return

    let subscriptionId = ''

    const onConnect = async () => {
      if (socket.id === undefined) return
      const clauses = query ? parseKeyValueFilterQuery(query) : []
      const geoExpression: GeoExpression = {
        coodsLatitude,
        coodsLongitude,
        maxDistance,
      }
      const response = await createNotification(socket.id, dataType, clauses, geoExpression)
      if (response.success) {
        subscriptionId = response.data
      } else {
        setAlert({ severity: 'error', message: response.errors.name })
      }
    }

    const onMessage = (ship: Ship) => {
      setGroupedShips((previous) => mergeGroupedShips(groupShips([ship]), previous, realtimeShipCountLimit))
    }

    socket.on('connect', onConnect)
    socket.on('message', onMessage)

    socket.connect()

    const cleanUpSubscription = () => {
      ;(async () => {
        if (subscriptionId) {
          const response = await deleteNotification(subscriptionId)
          if (!response.success) {
            setAlert({ severity: 'error', message: response.errors.name })
          }
        }
        socket.disconnect()
      })()
    }

    window.addEventListener('beforeunload', cleanUpSubscription)

    return () => {
      socket.off('connect', onConnect)
      socket.off('message', onMessage)
      cleanUpSubscription()
      window.removeEventListener('beforeunload', cleanUpSubscription)
    }
  }, [realtime, setAlert, realtimeShipCountLimit, query, coodsLatitude, coodsLongitude, maxDistance])

  useEffect(() => {
    if (!isReplaying) return

    const interval = 50
    const intervalId = setInterval(() => {
      setReplayCurrentTime((prevTime) => {
        if (!prevTime || !replayTimeRange) return prevTime
        if (prevTime.getTime() === replayTimeRange.end.getTime()) {
          setIsReplaying(false)
          return undefined
        }
        return new Date(
          Math.min(prevTime.getTime() + interval * replaySpeedMultiplier * 60, replayTimeRange.end.getTime()),
        )
      })
    }, interval)

    return () => clearInterval(intervalId)
  }, [isReplaying, replayTimeRange, replaySpeedMultiplier, setReplayCurrentTime])

  const onToggleReplaying = () => {
    if (realtime) {
      resetReplay()
      return
    }

    if (replayCurrentTime) {
      setIsReplaying((prev) => !prev)
      return
    }

    setReplayTimeRange(getReplayTimeRange(query, groupedShips))
    setReplayCurrentTime(replayTimeRange?.start)
    setIsReplaying(true)
  }

  if (isLoading) return <Loading />

  const sosIcon = (location: google.maps.LatLngLiteral, sos: number) => {
    let errorIcon
    switch (sos) {
      case 1:
        errorIcon = <Error style={{ fill: 'blue', backgroundColor: 'white', borderRadius: '50%' }} />
        break
      case 2:
        errorIcon = <Error style={{ fill: 'yellow', backgroundColor: 'gray', borderRadius: '50%' }} />
        break
      case 3:
        errorIcon = <Error style={{ fill: 'red', backgroundColor: 'white', borderRadius: '50%' }} />
        break
      default:
        return
    }

    return (
      <AdvancedMarker key="sos" position={location} zIndex={9999} anchorPoint={['20px', '50px']}>
        {errorIcon}
      </AdvancedMarker>
    )
  }

  const shipIcon = (location: google.maps.LatLngLiteral, alert?: number) => {
    if (alert === 1) return <AdvancedMarker key="ship" position={location} />

    return (
      <AdvancedMarker key="ship" position={location}>
        <Pin background={'#0f9d58'} borderColor={'#006425'} glyphColor={'#60d98f'} />
      </AdvancedMarker>
    )
  }

  const dataSourceMetric = (location: google.maps.LatLngLiteral, far: boolean, value?: string) => {
    if (!value) return

    return (
      <AdvancedMarker key="dataSource" position={location} zIndex={9998} anchorPoint={['50%', far ? '70px' : '60px']}>
        <Box
          sx={{
            height: '20px',
            minWidth: '35px',
            backgroundColor: 'white',
            fontSize: '12px',
            fontWeight: 'bold',
            border: 'solid 1px',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            whiteSpace: 'nowrap',
          }}
        >
          {value}
        </Box>
      </AdvancedMarker>
    )
  }

  const dataSourceCircle = (location: google.maps.LatLngLiteral, value?: string) => {
    if (!value) return
    const numberValue = Number(value)
    if (Number.isNaN(numberValue)) {
      return
    }
    const radius = Math.sqrt(Math.abs(numberValue)) * gain

    return (
      <Circle
        center={location}
        radius={radius}
        strokeOpacity={0}
        fillColor={color}
        fillOpacity={opacity}
        zIndex={6000}
      />
    )
  }

  const dataSourceOverlay = (location: google.maps.LatLngLiteral, far: boolean, value?: string) => {
    return (
      <>
        {dataSourceMetric(location, far, value)}
        {dataSourceCircle(location, value)}
      </>
    )
  }

  const overlays = Object.keys(groupedShips).map((id) => {
    const icons: React.ReactNode[] = []
    const locations: google.maps.LatLngLiteral[] = []

    const shipGroup = groupedShips[id]
    const shipCount = shipGroup.length

    for (let index = 0; index < shipCount; index++) {
      const ship = shipGroup[index]

      let location: google.maps.LatLngLiteral = {
        lat: ship.location.coordinates[1],
        lng: ship.location.coordinates[0],
      }

      const timestampAsDate = new Date(ship.timestamp)
      if (replayCurrentTime && timestampAsDate.getTime() > replayCurrentTime.getTime()) {
        if (index == 0) break

        const previousShip = shipGroup[index - 1]
        const previousTimestampAsDate = new Date(previousShip.timestamp)
        if (previousTimestampAsDate.getTime() > replayCurrentTime.getTime()) break

        const ratio =
          (replayCurrentTime.getTime() - previousTimestampAsDate.getTime()) /
          (timestampAsDate.getTime() - previousTimestampAsDate.getTime())
        const previousLocation: google.maps.LatLngLiteral = {
          lat: previousShip.location.coordinates[1],
          lng: previousShip.location.coordinates[0],
        }
        location = {
          lat: previousLocation.lat + (location.lat - previousLocation.lat) * ratio,
          lng: previousLocation.lng + (location.lng - previousLocation.lng) * ratio,
        }
      }

      let isLast = index === shipCount - 1
      if (!isLast && replayCurrentTime) {
        isLast = timestampAsDate.getTime() >= replayCurrentTime.getTime()
      }

      const sosIconElement = sosIcon(location, ship.data.sos)
      const dataSourceOverlayElement =
        showDataSource && dataSource && isLast
          ? dataSourceOverlay(location, !!sosIconElement, valueByPath(ship, dataSource)?.toString())
          : undefined
      icons.push(
        <div key={`${ship.id}-${ship._txTime || ''}-${timestampAsDate.toISOString()}`}>
          {dataSourceOverlayElement}
          {sosIconElement}
          {shipIcon(location, ship.data.alert)}
        </div>,
      )

      locations.push(location)
    }
    return (
      <div key={id}>
        {icons}
        {locations.length > 1 && <Polyline path={locations} zIndex={7000} />}
      </div>
    )
  })

  const circleSearchLatLng = (): google.maps.LatLngLiteral => {
    return {
      lat: Number(latitude),
      lng: Number(longitude),
    }
  }

  const isShowCircleCenter = latitude && longitude
  const circleSearchOverlay = (
    <div id="circleSearchPositionIcon">
      {isShowCircleCenter && (
        <AdvancedMarker key="circleCenter" position={circleSearchLatLng()}>
          <Pin background={'#606060'} borderColor={'#000000'} glyphColor={'#000000'} />
        </AdvancedMarker>
      )}
      {isShowCircleCenter && radius && (
        <Polygon
          paths={generateCirclePolygonPoints(circleSearchLatLng(), Number(radius) * 1000)}
          strokeOpacity={1}
          strokeColor="black"
          fillOpacity={0}
          zIndex={6000}
        />
      )}
    </div>
  )

  return (
    <APIProvider apiKey={apiKey}>
      <Box sx={{ position: 'relative', width: '100%', height: `calc(100vh - 56px)` }}>
        {!realtime && replayTimeRange && (
          <Box sx={{ position: 'absolute', top: '60px', left: '8px', width: '360px', zIndex: 1000 }}>
            <ReplayController
              isReplaying={isReplaying}
              speedMultiplier={replaySpeedMultiplier}
              startTime={replayTimeRange.start.toISOString()}
              endTime={replayTimeRange.end.toISOString()}
              currentTime={replayCurrentTime?.toISOString()}
              onToggleReplaying={onToggleReplaying}
              onChangeSpeedMultiplier={setReplaySpeedMultiplier}
            />
          </Box>
        )}
        <Map
          defaultCenter={centerLocation}
          defaultZoom={7}
          restriction={{
            latLngBounds: {
              west: -180,
              east: 180,
              north: 85,
              south: -85,
            },
            strictBounds: true,
          }}
          mapId="DEMO_MAP_ID"
          mapTypeControlOptions={{
            mapTypeIds: ['roadmap', 'satellite'],
          }}
          style={{ width: '100%', height: '100%' }}
        >
          {circleSearchOverlay}
          {overlays}
        </Map>
      </Box>
    </APIProvider>
  )
}
