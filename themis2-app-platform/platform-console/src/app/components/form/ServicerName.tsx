import { TextField } from '@mui/material'
import { useTranslations } from 'next-intl'

import type { Dispatch, SetStateAction } from 'react'

type FieldKey = 'name'

type ServicerNameProps = {
  value: string | undefined
  validationError: Partial<Record<FieldKey, string | null>>
  setValidationError: Dispatch<SetStateAction<Partial<Record<FieldKey, string | null>>>>
}

export function ServicerName({ value, validationError, setValidationError }: ServicerNameProps) {
  const t = useTranslations()
  const SERVICER_NAME_MAX_LENGTH = 50

  const changeServicerName = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValidationError: Partial<Record<FieldKey, string | null>> = { name: null }

    const value = event.target.value
    if (value.length > SERVICER_NAME_MAX_LENGTH) {
      newValidationError.name = t('validationError.client.exceededLength', {
        field: t('servicer.servicerName'),
        maxLength: SERVICER_NAME_MAX_LENGTH,
      })
    }

    setValidationError({ ...validationError, ...newValidationError })
  }

  return (
    <TextField
      id="name"
      name="name"
      label={t('servicer.servicerName')}
      required
      fullWidth
      size="small"
      defaultValue={value}
      slotProps={{
        htmlInput: {
          maxLength: SERVICER_NAME_MAX_LENGTH,
        },
        inputLabel: {
          shrink: true,
        },
      }}
      onChange={changeServicerName}
      error={!!validationError.name}
      helperText={validationError.name}
    />
  )
}
