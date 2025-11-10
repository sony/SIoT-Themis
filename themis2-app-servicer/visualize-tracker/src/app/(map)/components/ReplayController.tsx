'use client'
import PauseCircleOutlineIcon from '@mui/icons-material/PauseCircleOutline'
import PlayCircleOutlineIcon from '@mui/icons-material/PlayCircleOutline'
import { Button, LinearProgress, Box, Typography, Select, MenuItem } from '@mui/material'
import { format } from 'date-fns'
import React from 'react'

import type { SelectChangeEvent } from '@mui/material'

type ReplayControllerProps = {
  isReplaying: boolean
  speedMultiplier: number
  startTime: string
  endTime?: string
  currentTime?: string
  onToggleReplaying: () => void
  onChangeSpeedMultiplier: (newValue: number) => void
}

const speedMultiplierCandidates = [1, 2, 3, 5]

function formatDate(date: Date): string {
  return format(date, 'yyyy-MM-dd') + 'T' + format(date, 'HH:mm')
}

export function ReplayController({
  isReplaying,
  speedMultiplier,
  startTime,
  endTime,
  currentTime,
  onToggleReplaying,
  onChangeSpeedMultiplier,
}: ReplayControllerProps) {
  const handleSelectChange = (event: SelectChangeEvent): void => {
    const newValue = Number(event.target.value)
    if (speedMultiplierCandidates.includes(newValue)) {
      onChangeSpeedMultiplier(newValue)
    }
  }

  const startAsDate = new Date(startTime)
  const endAsDate = endTime ? new Date(endTime) : undefined
  const currentAsDate = currentTime ? new Date(currentTime) : undefined

  const progress = ((): number => {
    if (!currentAsDate || !endAsDate) {
      return 0
    }
    if (currentAsDate < startAsDate || startAsDate >= endAsDate) {
      return 0
    }
    if (currentAsDate >= endAsDate) {
      return 100
    }
    return ((currentAsDate.getTime() - startAsDate.getTime()) / (endAsDate.getTime() - startAsDate.getTime())) * 100
  })()

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'left',
        flexDirection: 'column',
        width: '100%',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'top', width: '100%' }}>
        <Box sx={{}}>
          <Button
            onClick={onToggleReplaying}
            sx={{ minWidth: 0, backgroundColor: 'transparent', padding: '4px 4px 4px 0px' }}
          >
            {isReplaying ? (
              <PauseCircleOutlineIcon sx={{ color: 'black', fontSize: 48 }} />
            ) : (
              <PlayCircleOutlineIcon sx={{ color: 'black', fontSize: 48 }} />
            )}
          </Button>
        </Box>

        <Box sx={{ flexGrow: 1, marginTop: '21px' }}>
          <LinearProgress
            variant="determinate"
            value={progress}
            sx={{
              backgroundColor: 'white',
              transition: 'none',
              '& .MuiLinearProgress-bar': { backgroundColor: 'red', transition: 'none' },
            }}
          />
          <Box sx={{ display: 'flex', justifyContent: 'space-between', width: '100%', paddingTop: 0 }}>
            <Typography sx={{ fontSize: '16px' }}>{formatDate(currentAsDate || startAsDate)}</Typography>
            <Typography sx={{ fontSize: '16px' }}>{endAsDate ? formatDate(endAsDate) : undefined}</Typography>
          </Box>
        </Box>
      </Box>

      <Box
        sx={{
          display: 'flex',
          alignItems: 'top',
          justifyContent: 'left',
          marginTop: '4px',
          width: '100%',
        }}
      >
        <Select
          value={speedMultiplier.toString()}
          onChange={handleSelectChange}
          sx={{
            borderColor: 'white',
            backgroundColor: 'white',
            minWidth: '16px',
            height: '24px',
            fontSize: '12px',
            marginLeft: '4px',
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
              border: '1px solid #fff',
            },
            '&:hover .MuiOutlinedInput-notchedOutline': {
              border: '1px solid #fff',
            },
          }}
        >
          {speedMultiplierCandidates.map((speedMultiplier, index) => (
            <MenuItem key={index} value={speedMultiplier} sx={{ fontSize: '12px', height: '24px' }}>
              {speedMultiplier}.0x
            </MenuItem>
          ))}
        </Select>
      </Box>
    </Box>
  )
}
