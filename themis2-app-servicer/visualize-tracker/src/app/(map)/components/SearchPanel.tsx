'use client'
import ClearIcon from '@mui/icons-material/Clear'
import { Box, Button, FormControlLabel, Switch, Select, MenuItem, OutlinedInput, IconButton } from '@mui/material'
import { DesktopDatePicker, DesktopTimePicker, LocalizationProvider } from '@mui/x-date-pickers'
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns'
import { useRouter, useSearchParams } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useCallback, useContext, useEffect, useState } from 'react'

import type { CircleForSearch } from '@/app/types/circle'
import type { ConditionClause } from '@/app/types/condition'
import type { SelectChangeEvent } from '@mui/material/Select'

import { Panel } from '@/app/(map)/components/Panel'
import { operators } from '@/app/constants/operators'
import { createGeoExpressionParameter } from '@/app/helpers/createGeoExpressionParameter'
import { isValidLatitude, isValidLongitude, isValidKilometerRadius } from '@/app/helpers/isValidCircleForSearch'
import { isValidOperator } from '@/app/helpers/isValidOperator'
import { parseCircleForSearchParameter } from '@/app/helpers/parseCircleForSearchParameter'
import { parseKeyValueFilterQuery } from '@/app/helpers/parseKeyValueFilterQuery'
import { parseTimeFilterQuery } from '@/app/helpers/parseTimeFilterQuery'
import { stringifyKeyValueFilterQuery } from '@/app/helpers/stringifyKeyValueFilterQuery'
import { stringifyTimeFilterQuery } from '@/app/helpers/stringifyTimeFilterQuery'
import { updateSearchParams } from '@/app/helpers/updateSearchParams'
import { SnackbarContext } from '@/app/SnackbarProvider'
import { socket } from '@/app/socket'
import searchMetrics from '@/data/searchMetrics.json'

const maxLength = Number(process.env.NEXT_PUBLIC_SEARCH_KEY_VALUE_MAX_LENGTH!)
const maxRadius = Number(process.env.NEXT_PUBLIC_SEARCH_CIRCLE_MAX_RADIUS!)

type SearchPanelProps = {
  panelValue: number
}

const defaultCircleForSearch: CircleForSearch = {
  latitude: '',
  longitude: '',
  radius: '',
}

const defaultGeoExpressionParameters: [key: string, value: string][] = [
  ['georel', ''],
  ['coords', ''],
]

const defaultKeyValue: ConditionClause = {
  field: '',
  operator: '==',
  value: '',
}

export function SearchPanel({ panelValue }: SearchPanelProps) {
  const t = useTranslations('SearchPanel')
  const { setAlert } = useContext(SnackbarContext)
  const { replace } = useRouter()
  const searchParams = useSearchParams()

  const [startDate, setStartDate] = useState<Date | null>(null)
  const [startTime, setStartTime] = useState<Date | null>(null)
  const [endDate, setEndDate] = useState<Date | null>(null)
  const [endTime, setEndTime] = useState<Date | null>(null)
  const [enableRealtime, setEnableRealtime] = useState(false)
  const [isConnecting, setIsConnecting] = useState(false)
  const [geoLocationSearchMode, setGeoLocationSearchMode] = useState<string>('whole')
  const [circleForSearch, setCircleForSearch] = useState<CircleForSearch>(defaultCircleForSearch)
  const [keyValues, setKeyValues] = useState<ConditionClause[]>([defaultKeyValue])
  const [editingKeyValueIndex, setEditingKeyValueIndex] = useState<number | null>(null)
  const query = searchParams?.get('q')
  const realtime = searchParams?.get('realtime')
  const { latitude, longitude, radius } = parseCircleForSearchParameter(searchParams, false)

  const initializeSearchValues = useCallback(() => {
    if (query) {
      const timeFilterConditionClauses = parseTimeFilterQuery(query)
      const startDateTimeStr = timeFilterConditionClauses.find((clause) => clause.operator === '>=')?.value
      const endDateTimeStr = timeFilterConditionClauses.find((clause) => clause.operator === '<=')?.value
      if (startDateTimeStr) {
        const startDateTime = new Date(startDateTimeStr)
        setStartDate(startDateTime)
        setStartTime(startDateTime)
      } else {
        setStartDate(null)
        setStartTime(null)
      }

      if (endDateTimeStr) {
        const endDateTime = new Date(endDateTimeStr)
        setEndDate(endDateTime)
        setEndTime(endDateTime)
      } else {
        setEndDate(null)
        setEndTime(null)
      }

      const keyValuesFromSearchParams = parseKeyValueFilterQuery(query)
      if (keyValuesFromSearchParams.length < maxLength) {
        keyValuesFromSearchParams.push(defaultKeyValue)
      }
      if (keyValuesFromSearchParams.length > 0) setKeyValues(keyValuesFromSearchParams)
    }
    setEnableRealtime(realtime === 'true')
  }, [query, realtime])

  useEffect(() => {
    initializeSearchValues()
  }, [initializeSearchValues])

  useEffect(() => {
    if (latitude && longitude && radius) {
      setGeoLocationSearchMode('circle')
      setCircleForSearch({
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      })
    }
  }, [latitude, longitude, radius])

  useEffect(() => {
    if (editingKeyValueIndex !== null) {
      setEditingKeyValueIndex(null)
      const notEnteredKeyValue = keyValues.find((keyValue) => keyValue.field === '' || keyValue.value === '')
      if (keyValues.length >= maxLength || notEnteredKeyValue) return
      const keyValue = keyValues[editingKeyValueIndex]
      if (!keyValue.field || !keyValue.value) return
      setKeyValues((prevs) => [...prevs, defaultKeyValue])
    }
  }, [editingKeyValueIndex, keyValues])

  useEffect(() => {
    const onConnect = () => {
      setIsConnecting(false)
    }

    socket.on('connect', onConnect)

    return () => {
      socket.off('connect', onConnect)
    }
  }, [setIsConnecting])

  const validateKeyValue = (): { isValid: true } | { isValid: false; message: string } => {
    for (const keyValue of keyValues) {
      if (!keyValue.field && keyValue.value) {
        return {
          isValid: false,
          message: t('fieldSelctError'),
        }
      }
      if (!keyValue.value && keyValue.field) {
        return {
          isValid: false,
          message: t('valueInputError'),
        }
      }
    }
    return {
      isValid: true,
    }
  }

  const removeDefaultKeyValue = (): ConditionClause[] => {
    return keyValues.filter((keyValue) => keyValue.field && keyValue.value)
  }

  const validateCircleForSearch = (): { isValid: true } | { isValid: false; message: string } => {
    if (!isValidLatitude(circleForSearch.latitude)) {
      return {
        isValid: false,
        message: t('latitudeInputError'),
      }
    }
    if (!isValidLongitude(circleForSearch.longitude)) {
      return {
        isValid: false,
        message: t('longitudeInputError'),
      }
    }
    if (!isValidKilometerRadius(circleForSearch.radius)) {
      return {
        isValid: false,
        message: t('radiusInputError'),
      }
    }

    return {
      isValid: true,
    }
  }

  const handleSearch = () => {
    const timeFilterConditionClauses: ConditionClause[] = []
    if (startDate) {
      const startHour = startTime ? startTime.getHours() : 0
      const startMinute = startTime ? startTime.getMinutes() : 0
      const startDateTime = new Date(
        startDate.getFullYear(),
        startDate.getMonth(),
        startDate.getDate(),
        startHour,
        startMinute,
        0,
      )
      timeFilterConditionClauses.push({ field: 'timestamp', operator: '>=', value: startDateTime.toISOString() })
    }

    if (endDate) {
      const endHour = endTime ? endTime.getHours() : 0
      const endMinute = endTime ? endTime.getMinutes() : 0
      const endDateTime = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate(), endHour, endMinute, 0)
      timeFilterConditionClauses.push({ field: 'timestamp', operator: '<=', value: endDateTime.toISOString() })
    }

    let geoExpressionParameters: [key: string, value: string][] = defaultGeoExpressionParameters
    if (geoLocationSearchMode === 'circle') {
      const circlePointValidateResult = validateCircleForSearch()
      if (!circlePointValidateResult.isValid) {
        setAlert({ severity: 'error', message: circlePointValidateResult.message })
        return
      }
      geoExpressionParameters = createGeoExpressionParameter({
        coodsLatitude: circleForSearch.latitude,
        coodsLongitude: circleForSearch.longitude,
        maxDistance: circleForSearch.radius,
      })
    }

    const keyValuesValidateResult = validateKeyValue()
    if (!keyValuesValidateResult.isValid) {
      setAlert({ severity: 'error', message: keyValuesValidateResult.message })
      return
    }

    const queries: string[] = []
    const timeFilterQuery = stringifyTimeFilterQuery(timeFilterConditionClauses)
    if (timeFilterQuery) queries.push(timeFilterQuery)
    const keyValueFilterQuery = stringifyKeyValueFilterQuery(removeDefaultKeyValue())
    if (keyValueFilterQuery) queries.push(keyValueFilterQuery)
    const query = queries.join(';')
    const searchTime = new Date().getTime().toString()
    const isExistGeoExpressionParameters =
      geoExpressionParameters.length === 2 && !!geoExpressionParameters[0][1] && !!geoExpressionParameters[1][1]

    if (query || isExistGeoExpressionParameters) {
      const params = updateSearchParams(
        [['q', query], ['searchTime', searchTime], ...geoExpressionParameters],
        searchParams,
      )
      replace(`?${params.toString()}`)
    } else {
      setAlert({
        severity: 'warning',
        message: t('missingSearchInputError'),
      })
    }
  }

  const selectGeoLocationSearchMode = (event: SelectChangeEvent) => {
    setGeoLocationSearchMode(event.target.value)
    setCircleForSearch(defaultCircleForSearch)
    const params = updateSearchParams(
      [
        ['latitude', ''],
        ['longitude', ''],
        ['radius', ''],
      ],
      searchParams,
    )
    replace(`?${params.toString()}`)
  }

  const createCircleForSearchParameter = (target: 'latitude' | 'longitude' | 'radius', value: string) => {
    const param: [key: string, value: string] = [target, '']

    if (target === 'latitude' && !isValidLatitude(value)) return [param]
    if (target === 'longitude' && !isValidLongitude(value)) return [param]
    if (target === 'radius' && !isValidKilometerRadius(value)) return [param]

    if (target === 'radius') {
      param[1] = (Number(value) * 1000).toString()
    } else {
      param[1] = value
    }
    return [param]
  }

  const changeCircleForSearch = (
    event: React.ChangeEvent<HTMLInputElement>,
    target: 'latitude' | 'longitude' | 'radius',
  ) => {
    const value = event.target.value
    setCircleForSearch((prev) => ({ ...prev, [target]: value }))

    if (target === 'latitude' && value && !isValidLatitude(value)) {
      setAlert({ severity: 'error', message: t('latitudeInputError') })
    }
    if (target === 'longitude' && value && !isValidLongitude(value)) {
      setAlert({ severity: 'error', message: t('longitudeInputError') })
    }
    if (target === 'radius' && value && !isValidKilometerRadius(value)) {
      setAlert({ severity: 'error', message: t('radiusInputError') })
    }

    const circleParams = createCircleForSearchParameter(target, value)
    const params = updateSearchParams(circleParams, searchParams)
    replace(`?${params.toString()}`)
  }

  const removeKeyValueInputs = (targetIndex: number) => {
    if (keyValues.length === 1) return
    setKeyValues((prevs) => prevs.filter((_, index) => index !== targetIndex))
  }

  const updateKeyValue = (targetIndex: number, key: 'field' | 'operator' | 'value', value: string) => {
    setKeyValues((prevs) => prevs.map((prev, index) => (index === targetIndex ? { ...prev, [key]: value } : prev)))
    setEditingKeyValueIndex(targetIndex)
  }

  const selectField = (event: SelectChangeEvent, targetIndex: number) => {
    updateKeyValue(targetIndex, 'field', event.target.value)
  }

  const selectOperator = (event: SelectChangeEvent, targetIndex: number) => {
    const operator = event.target.value
    if (!isValidOperator(operator)) return
    updateKeyValue(targetIndex, 'operator', operator)
  }

  const changeValue = (event: React.ChangeEvent<HTMLInputElement>, targetIndex: number) => {
    updateKeyValue(targetIndex, 'value', event.target.value)
  }

  const handleRealtime = (event: React.ChangeEvent<HTMLInputElement>) => {
    let geoExpressionParameters: [key: string, value: string][] = []
    if (geoLocationSearchMode === 'circle') {
      const circlePointValidateResult = validateCircleForSearch()
      if (!circlePointValidateResult.isValid) {
        setAlert({ severity: 'error', message: circlePointValidateResult.message })
        return
      }
      geoExpressionParameters = createGeoExpressionParameter({
        coodsLatitude: circleForSearch.latitude,
        coodsLongitude: circleForSearch.longitude,
        maxDistance: circleForSearch.radius,
      })
    }

    const keyValuesValidateResult = validateKeyValue()
    if (!keyValuesValidateResult.isValid) {
      setAlert({ severity: 'error', message: keyValuesValidateResult.message })
      return
    }

    setEnableRealtime(event.target.checked)
    setStartDate(null)
    setStartTime(null)
    setEndDate(null)
    setEndTime(null)
    setIsConnecting(event.target.checked)

    const queries: string[] = []
    const keyValueFilterQuery = stringifyKeyValueFilterQuery(removeDefaultKeyValue())
    if (keyValueFilterQuery) queries.push(keyValueFilterQuery)
    const query = queries.join(';')

    const params = updateSearchParams(
      [
        ['realtime', event.target.checked],
        ['q', event.target.checked ? query : ''],
        ...(event.target.checked ? geoExpressionParameters : defaultGeoExpressionParameters),
      ],
      searchParams,
    )
    replace(`/?${params.toString()}`)
  }

  const circleInput = () => (
    <Box sx={{ marginTop: '5px' }}>
      <Box sx={{ display: 'flex', gap: '10px' }}>
        <OutlinedInput
          name="latitude"
          type="number"
          value={circleForSearch.latitude}
          sx={{ width: '150px', backgroundColor: '#fff', '& .MuiSelect-select': { paddingLeft: '10px' } }}
          autoComplete="off"
          placeholder={t('latitude')}
          disabled={enableRealtime}
          slotProps={{
            input: {
              min: -85,
              max: 85,
            },
          }}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) => changeCircleForSearch(event, 'latitude')}
        />
        <OutlinedInput
          name="longitude"
          type="number"
          value={circleForSearch.longitude}
          sx={{ width: '150px', backgroundColor: '#fff', '& .MuiSelect-select': { paddingLeft: '10px' } }}
          autoComplete="off"
          placeholder={t('longitude')}
          disabled={enableRealtime}
          slotProps={{
            input: {
              min: -180,
              max: 180,
            },
          }}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) => changeCircleForSearch(event, 'longitude')}
        />
      </Box>

      <Box sx={{ marginTop: '5px', display: 'flex', gap: '10px' }}>
        <OutlinedInput
          name="radius"
          type="number"
          value={circleForSearch.radius}
          sx={{ width: '150px', backgroundColor: '#fff', '& .MuiSelect-select': { paddingLeft: '10px' } }}
          autoComplete="off"
          placeholder={t('radius')}
          disabled={enableRealtime}
          slotProps={{
            input: {
              min: 1,
              max: maxRadius,
            },
          }}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) => changeCircleForSearch(event, 'radius')}
        />
      </Box>
    </Box>
  )

  const keyValueInputs = keyValues.map((keyValue, index) => (
    <Box key={index} sx={{ display: 'flex', marginTop: index !== 0 ? '5px' : '0px' }}>
      <Select
        name="field"
        value={keyValue.field}
        sx={{
          width: '110px',
          minWidth: '110px',
          marginRight: '5px',
          fontSize: 'smaller',
          backgroundColor: '#fff',
          '& .MuiSelect-select': { paddingLeft: '10px' },
        }}
        disabled={enableRealtime}
        displayEmpty
        onChange={(event: SelectChangeEvent) => selectField(event, index)}
        renderValue={(selected) => {
          if (!selected) {
            return t('fieldSelect')
          }
          return searchMetrics.find((metric) => metric.field === selected)?.display
        }}
      >
        {searchMetrics.map((metric, keyIndex) => (
          <MenuItem key={keyIndex} value={metric.field}>
            {metric.display}
          </MenuItem>
        ))}
      </Select>
      <Select
        name="operator"
        value={keyValue.operator}
        sx={{
          width: '64px',
          minWidth: '64px',
          marginRight: '5px',
          backgroundColor: '#fff',
          '& .MuiSelect-select': { paddingLeft: '10px' },
        }}
        disabled={enableRealtime}
        onChange={(event: SelectChangeEvent) => selectOperator(event, index)}
      >
        {operators.map((operator, index) => (
          <MenuItem key={index} value={operator}>
            {operator}
          </MenuItem>
        ))}
      </Select>
      <OutlinedInput
        name="value"
        size="small"
        value={keyValue.value}
        sx={{
          width: '117px',
          backgroundColor: '#fff',
          '& .MuiInputBase-input': { paddingLeft: '10px', paddingRight: '10px' },
        }}
        autoComplete="off"
        placeholder={t('value')}
        disabled={enableRealtime}
        onChange={(event: React.ChangeEvent<HTMLInputElement>) => changeValue(event, index)}
      />
      <IconButton
        edge="end"
        size="small"
        sx={{ color: 'grey' }}
        onClick={() => removeKeyValueInputs(index)}
        disabled={enableRealtime}
      >
        <ClearIcon fontSize="small" />
      </IconButton>
    </Box>
  ))

  return (
    <Panel value={panelValue} index={1}>
      <Box sx={{ padding: '16px' }}>
        <FormControlLabel
          sx={{ padding: '20px 0px' }}
          control={<Switch checked={enableRealtime} onChange={handleRealtime} disabled={isConnecting} />}
          label={t('realtime')}
        />
        <LocalizationProvider dateAdapter={AdapterDateFns}>
          <Box sx={{ display: 'flex', gap: '16px' }}>
            <Box sx={{ flex: 6 }}>
              <label>{t('fromDate')}</label>
              <DesktopDatePicker
                value={startDate}
                onChange={(newValue) => setStartDate(newValue)}
                disabled={enableRealtime}
                format="yyyy-MM-dd"
                sx={{ '& .MuiInputBase-root': { backgroundColor: '#fff' } }}
              />
            </Box>
            <Box sx={{ flex: 4 }}>
              <label>{t('time')}</label>
              <DesktopTimePicker
                value={startTime}
                onChange={(newValue) => setStartTime(newValue)}
                disabled={enableRealtime}
                ampm={false}
                sx={{ '& .MuiInputBase-root': { backgroundColor: '#fff' } }}
              />
            </Box>
          </Box>

          <Box sx={{ display: 'flex', gap: '16px', marginTop: '16px' }}>
            <Box sx={{ flex: 6 }}>
              <label>{t('toDate')}</label>
              <DesktopDatePicker
                value={endDate}
                onChange={(newValue) => setEndDate(newValue)}
                disabled={enableRealtime}
                format="yyyy-MM-dd"
                sx={{ '& .MuiInputBase-root': { backgroundColor: '#fff' } }}
              />
            </Box>
            <Box sx={{ flex: 4 }}>
              <label>{t('time')}</label>
              <DesktopTimePicker
                value={endTime}
                onChange={(newValue) => setEndTime(newValue)}
                disabled={enableRealtime}
                ampm={false}
                sx={{ '& .MuiInputBase-root': { backgroundColor: '#fff' } }}
              />
            </Box>
          </Box>
        </LocalizationProvider>

        <Box sx={{ marginTop: '16px' }}>
          <label>{t('searchGeoLocation')}</label>
          <Box>
            <Select
              name="geoLocationSearchMode"
              value={geoLocationSearchMode}
              sx={{ width: '200px', backgroundColor: '#fff' }}
              disabled={enableRealtime}
              onChange={selectGeoLocationSearchMode}
            >
              <MenuItem value="whole">{t('whole')}</MenuItem>
              <MenuItem value="circle">{t('circle')}</MenuItem>
            </Select>
          </Box>
          {geoLocationSearchMode === 'circle' && circleInput()}
        </Box>

        <Box sx={{ marginTop: '16px' }}>
          <label>{t('searchKeyValue')}</label>
          {keyValueInputs}
        </Box>

        <Button
          variant="contained"
          fullWidth
          onClick={handleSearch}
          sx={{ marginTop: '16px' }}
          disabled={enableRealtime}
        >
          {t('search')}
        </Button>
      </Box>
    </Panel>
  )
}
