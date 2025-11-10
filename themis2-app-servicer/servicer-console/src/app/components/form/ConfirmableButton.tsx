import { Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions, Button } from '@mui/material'
import { useState } from 'react'

type ConfirmableButtonProps = {
  title: string
  content: string
  okLabel: string
  cancelLabel: string
  onContinue: () => void
  children: React.ReactNode
}

export function ConfirmableButton({
  title,
  content,
  okLabel,
  cancelLabel,
  onContinue,
  children,
}: ConfirmableButtonProps) {
  const [open, setOpen] = useState(false)

  const handleContinue = () => {
    setOpen(false)
    onContinue()
  }

  return (
    <>
      <Button
        variant="contained"
        onClick={() => {
          setOpen(true)
        }}
      >
        {children}
      </Button>
      <Dialog
        open={open}
        onClose={() => {
          setOpen(false)
        }}
      >
        <DialogTitle>{title}</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ whiteSpace: 'pre-line' }}>{content}</DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setOpen(false)
            }}
          >
            {cancelLabel}
          </Button>
          <Button onClick={handleContinue}>{okLabel}</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
