import { Box, TextField } from '@mui/material'
import { useTranslations } from 'next-intl'
import { useState } from 'react'

import type { Dispatch, SetStateAction } from 'react'

import { isInvalidEndpoint } from '@/app/helpers/isInvalidEndpoint'

type EndpointProps = {
  values?: string[]
  validationError: Record<string, string | null>
  setValidationError: Dispatch<SetStateAction<Partial<Record<'endpoint', string | null>>>>
  rowIndex: number
  onChange: (index: number, newValue: string) => void
  typeId: string
  subscriptions: { id: number; endpoint: string }[]
}

type KeyValueItem = { id: string; value: string }

export function Endpoint({
  values,
  validationError,
  setValidationError,
  rowIndex,
  onChange,
  typeId,
  subscriptions,
}: EndpointProps) {
  const t = useTranslations()
  const now = Date.now()

  const [keyValues, setKeyValues] = useState<KeyValueItem[]>(() => {
    const dbValues = values ?? []

    const mappedValues = dbValues.map((v, i) => ({
      id: `endpoint-${typeId}-${subscriptions[i]?.id ?? 'new'}-${rowIndex}-${i}`,
      value: v,
    }))

    const filled = mappedValues.every((item) => item.value.trim() !== '')

    if (filled) {
      // Always have one empty endpoint at the end
      mappedValues.push({
        id: `endpoint-${typeId}-new-${now}`,
        value: '',
      })
    }

    return mappedValues.length > 0 ? mappedValues : [{ id: `endpoint-new-${rowIndex}-0`, value: '' }]
  })

  const updateKeyValue = (targetIndex: number, newValue: string) => {
    const updatedValues = [...keyValues]
    updatedValues[targetIndex].value = newValue
    setKeyValues(updatedValues)

    onChange(targetIndex, newValue)
  }

  // Check if endpoint is a valid URL and doesn't include invalid orion values
  // Invalid orion values are as follows  <>"'=;()
  const validateField = (value: string) => {
    if (value && isInvalidEndpoint(value)) {
      return t('ValidationError.Client.bannedEndpointCharacters', {
        field: t('CustomerEdit.endpointInputLabel'),
      })
    } else if (value && !URL.canParse(value)) {
      return t('ValidationError.Client.invalid', {
        field: t('CustomerEdit.endpointInputLabel'),
      })
    }

    return null
  }

  const changeEndpoint = (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>, targetIndex: number) => {
    const newValue = event.target.value
    updateKeyValue(targetIndex, newValue)

    const fieldValidationError = validateField(newValue)
    const errorKey = event.target.id
    setValidationError((prev) => ({
      ...prev,
      [errorKey]: fieldValidationError,
    }))

    // Add a new empty endpoint when the last one is filled
    const isLastField = targetIndex === keyValues.length - 1
    const lastValueFilled = keyValues[keyValues.length - 1]?.value.trim() !== ''

    if (isLastField && lastValueFilled) {
      const newId = `endpoint-${typeId}-new-${rowIndex}-${now}`
      setKeyValues((prev) => [...prev, { id: newId, value: '' }])
    }
  }

  return (
    <Box>
      {keyValues.map((item, index) => (
        <TextField
          key={item.id}
          id={`${item.id}`}
          name={`${item.id}`}
          fullWidth
          size="small"
          sx={{ width: '550px', marginBottom: '5px', marginLeft: '20px' }}
          value={item.value}
          onChange={(e) => changeEndpoint(e, index)}
          placeholder={t('CustomerEdit.exampleUrl')}
          error={!!validationError[`${item.id}`]}
          helperText={validationError[`${item.id}`]}
        />
      ))}
    </Box>
  )
}
