'use client'
import path from 'path'

import { Button, Box, OutlinedInput, FormHelperText } from '@mui/material'
import { useTranslations } from 'next-intl'
import { useEffect, useContext, useState } from 'react'
import { useFormState } from 'react-dom'

import { updateReceiverSensor } from './actions/receiverSensor'
import { isEmpty } from './helpers/isEmpty'
import { SnackbarContext } from './SnackbarProvider'

import type { ServerActionResponse } from '@/app/types/actions'

type FieldKey = 'file'
type ValidationError = Partial<Record<FieldKey, string | null>>

export default function CsvUpload() {
  const initialState: ServerActionResponse = {
    success: false,
    errors: {},
  }
  const [state, formAction] = useFormState(updateReceiverSensor, initialState)
  const [validationError, setValidationError] = useState<ValidationError>({})
  const { setAlert } = useContext(SnackbarContext)
  const t = useTranslations()

  useEffect(() => {
    if (state.success) {
      setAlert({
        severity: 'success',
        message: t('csvUpload.success'),
      })
    } else {
      if (isEmpty(state.errors)) return
      const errorMessage = Object.values(state.errors).join('\n')
      setAlert({
        severity: 'error',
        message: errorMessage,
      })
      setValidationError((validationError) => ({ ...validationError, ...state.errors }))
    }
  }, [state, setAlert, t])

  const changeFile = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValidationError: Partial<Record<FieldKey, string | null>> = { file: null }

    const files: FileList | null = event.target.files

    if (files && files[0]) {
      const selectedFile = files[0]
      if (path.extname(selectedFile.name) !== '.csv' || selectedFile.type !== 'text/csv') {
        newValidationError.file = t('validationError.client.extensionInvalid')
      }
    }
    setValidationError({ ...validationError, ...newValidationError })
  }

  return (
    <Box
      sx={{
        width: '500px',
        position: 'absolute',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        textAlign: 'right',
      }}
    >
      <form action={formAction}>
        <OutlinedInput
          type="file"
          id="file"
          name="file"
          onChange={changeFile}
          inputProps={{
            accept: '.csv',
          }}
          sx={{
            width: '500px',
            input: {
              paddingBottom: '13.5px',
              paddingTop: '5.5px',
            },
          }}
          error={!!validationError.file}
        />
        <FormHelperText error={!!validationError.file}>{validationError.file}</FormHelperText>
        <Button variant="contained" type="submit" sx={{ marginTop: '20px' }}>
          {t('csvUpload.submit')}
        </Button>
      </form>
    </Box>
  )
}
