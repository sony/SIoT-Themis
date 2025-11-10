'use client'
import { createTheme } from '@mui/material/styles'
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
})

export const theme = createTheme({
  typography: {
    fontFamily: inter.style.fontFamily,
  },
  components: {
    // eslint-disable-next-line @typescript-eslint/naming-convention
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
        },
      },
    },
  },
})
