import { Box, CircularProgress } from '@mui/material'
import React from 'react'

export function Loading() {
  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
      }}
    >
      <CircularProgress size={80} />
    </Box>
  )
}
