import { Alert, Snackbar } from '@mui/material'

import type { AlertColor, SnackbarCloseReason } from '@mui/material'

export function AlertSnackbar({
  severity,
  message,
  onClose,
}: {
  severity: AlertColor
  message: string
  onClose: () => void
}) {
  const handleClose = (_: React.SyntheticEvent | Event, reason?: SnackbarCloseReason) => {
    if (reason === 'clickaway') {
      return
    }
    onClose()
  }

  return (
    <>
      <Snackbar
        open={!!message}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        autoHideDuration={10000}
        onClose={handleClose}
      >
        <Alert onClose={handleClose} severity={severity} variant="filled" sx={{ width: '100%' }}>
          {message.split('\n').map((line, index) => (
            <div key={index}>{line}</div>
          ))}
        </Alert>
      </Snackbar>
    </>
  )
}
