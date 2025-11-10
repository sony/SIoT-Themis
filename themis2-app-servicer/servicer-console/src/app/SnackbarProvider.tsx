'use client'

import { useState, createContext } from 'react'

import type { AlertColor } from '@mui/material'
import type { Dispatch, SetStateAction } from 'react'

import { AlertSnackbar } from '@/app/components/AlertSnackbar'

type Alert = {
  severity: AlertColor
  message: string
}

type Snackbar = {
  setAlert: Dispatch<SetStateAction<Alert>>
}

export const SnackbarContext = createContext<Snackbar>({
  setAlert: () => {},
})

export function SnackbarProvider({ children }: { children: React.ReactNode }) {
  const initialAlert: Alert = {
    severity: 'success',
    message: '',
  }

  const [alert, setAlert] = useState<Alert>(initialAlert)

  const onCloseSnackbar = () => {
    setAlert({
      severity: alert.severity,
      message: '',
    })
  }

  return (
    <>
      <SnackbarContext.Provider value={{ setAlert }}>{children}</SnackbarContext.Provider>

      <AlertSnackbar severity={alert.severity} message={alert.message} onClose={onCloseSnackbar} />
    </>
  )
}
