'use client'
import { Box, Checkbox, FormControlLabel, MenuItem, Select, Slider, TextField } from '@mui/material'
import { useRouter, useSearchParams } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useState } from 'react'

import type { SelectChangeEvent } from '@mui/material'

import { Panel } from '@/app/(map)/components/Panel'
import { parseDisplayParameter } from '@/app/helpers/parseDisplayParameter'
import { updateSearchParams } from '@/app/helpers/updateSearchParams'
import metrics from '@/data/metrics.json'

type DisplayPanelProps = {
  panelValue: number
}

export function DisplayPanel({ panelValue }: DisplayPanelProps) {
  const t = useTranslations('DisplayPanel')
  const { replace } = useRouter()
  const readOnlySearchParams = useSearchParams()
  const searchParams = readOnlySearchParams ? new URLSearchParams(readOnlySearchParams) : new URLSearchParams()
  const { showDataSource, dataSource, color, opacity } = parseDisplayParameter(searchParams, false)
  const [opacityInState, setOpacityInState] = useState<number>(opacity)

  const replaceUrl = (newKeyAndValues: [key: string, value: string | boolean][]) => {
    const params = updateSearchParams(newKeyAndValues, searchParams)
    replace(`/?${params.toString()}`)
  }

  const handleDataSourceChange = (event: SelectChangeEvent): void => {
    const value = event.target.value
    replaceUrl([['dataSource', value]])
  }

  const handleOpacityChange = (event: Event, value: number | number[]) => {
    if (typeof value !== 'number') return
    setOpacityInState(value)
  }

  const handleOpacityChangeCommitted = (event: React.SyntheticEvent | Event, value: number | number[]) => {
    if (typeof value !== 'number') return
    replaceUrl([['opacity', value.toString()]])
  }

  return (
    <Panel value={panelValue} index={0}>
      <Box sx={{ padding: '40px 30px' }}>
        <FormControlLabel
          control={
            <Checkbox
              checked={showDataSource}
              onChange={(event) => replaceUrl([['showDataSource', event.target.checked]])}
            />
          }
          label={t('overlay')}
        />
        <Box sx={{ marginTop: '20px', display: 'flex', flexDirection: 'column' }}>
          <label>{t('dataSource')}</label>
          <Select
            sx={{ width: '200px', backgroundColor: '#fff' }}
            onChange={handleDataSourceChange}
            value={dataSource || ''}
            size="small"
            displayEmpty
            renderValue={(selected) => {
              if (!selected) {
                return t('select')
              }
              return metrics.find((list) => list.field === selected)?.display
            }}
          >
            {metrics.map((list, index) => (
              <MenuItem key={index} value={list.field}>
                {list.display}
              </MenuItem>
            ))}
          </Select>
        </Box>
        <Box sx={{ marginTop: '30px', display: 'flex', flexDirection: 'column' }}>
          <label>{t('color')}</label>
          <TextField
            type="color"
            size="small"
            sx={{ width: '100px' }}
            value={color}
            onChange={(event) => replaceUrl([['color', event.target.value]])}
          />
        </Box>
        <Box sx={{ marginTop: '30px', width: '250px' }}>
          <label>{t('opacity')}</label>
          <Slider
            value={opacityInState}
            valueLabelDisplay="auto"
            onChange={handleOpacityChange}
            onChangeCommitted={handleOpacityChangeCommitted}
            marks={[
              { value: 0, label: '0%' },
              { value: 1, label: '100%' },
            ]}
            min={0}
            max={1}
            step={0.01}
            valueLabelFormat={(value) => (value * 100).toFixed()}
          />
        </Box>
      </Box>
    </Panel>
  )
}
