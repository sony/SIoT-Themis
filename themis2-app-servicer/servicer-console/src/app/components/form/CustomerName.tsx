import { TextField } from '@mui/material'
import { useTranslations } from 'next-intl'

import type { Dispatch, SetStateAction } from 'react'

type FieldKey = 'name'

type CustomerNameProps = {
  value: string | undefined
  validationError: Partial<Record<FieldKey, string | null>>
  setValidationError: Dispatch<SetStateAction<Partial<Record<FieldKey, string | null>>>>
}

export function CustomerName({ value, validationError, setValidationError }: CustomerNameProps) {
  const t = useTranslations()
  const CUSTOMER_NAME_MAX_LENGTH = 50

  const changeCustomerName = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValidationError: Partial<Record<FieldKey, string | null>> = { name: null }

    const value = event.target.value
    if (value.length > CUSTOMER_NAME_MAX_LENGTH) {
      newValidationError.name = t('ValidationError.Client.exceededLength', {
        field: t('CustomerEdit.customerNameInputLabel'),
        maxLength: CUSTOMER_NAME_MAX_LENGTH,
      })
    }

    setValidationError({ ...validationError, ...newValidationError })
  }

  return (
    <TextField
      id="name"
      name="name"
      label={t('CustomerEdit.customerNameInputLabel')}
      required
      fullWidth
      size="small"
      defaultValue={value}
      slotProps={{
        htmlInput: {
          maxLength: CUSTOMER_NAME_MAX_LENGTH,
        },
        inputLabel: {
          shrink: true,
        },
      }}
      onChange={changeCustomerName}
      error={!!validationError.name}
      helperText={validationError.name}
    />
  )
}
