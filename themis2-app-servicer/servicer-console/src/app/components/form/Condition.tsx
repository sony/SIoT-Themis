import { Box, Button, MenuItem, Select, TextField } from '@mui/material'
import { useTranslations } from 'next-intl'
import { useState } from 'react'

import type { SelectChangeEvent } from '@mui/material'

import { operators } from '@/app/constants/operators'
import { isValidOperator } from '@/app/helpers/isValidOperator'

type FieldKey = 'key' | 'operator' | 'value'

type ConditionProps = {
  rowIndex: number
  onChange: (updatedConditions: { key: string; operator: string; value: string }[], rowIndex: number) => void
  typeId: string
  conditions: { id: number; key: string; operator: string; value: string }[]
}

type KeyValueItem = { id: string; key: string; operator: string; value: string }

const defaultKeyValue = {
  id: '',
  key: '',
  operator: '==',
  value: '',
}

export function Condition({ rowIndex, onChange, typeId, conditions }: ConditionProps) {
  const t = useTranslations()

  const [keyValues, setKeyValues] = useState<KeyValueItem[]>(() => {
    const mappedValues = conditions.map((v, i) => ({
      id: `${typeId}-${v.id ?? 'new'}-${rowIndex}-${i}`,
      key: v.key || '',
      operator: v.operator || '==',
      value: v.value || '',
    }))

    // If all fields are filled, add a new empty condition
    const allFilled = mappedValues.every((item) => item.key && item.operator && item.value)
    if (allFilled) {
      mappedValues.push({
        id: `${typeId}-new-${Date.now()}`,
        key: '',
        operator: '==',
        value: '',
      })
    }

    return mappedValues.length > 0
      ? mappedValues
      : [{ id: `${typeId}-new-${rowIndex}-0`, key: '', operator: '==', value: '' }]
  })

  const updateKeyValue = (targetIndex: number, key: 'key' | 'operator' | 'value', newValue: string) => {
    const updatedValues = [...keyValues]
    updatedValues[targetIndex][key] = newValue
    setKeyValues(updatedValues)

    onChange(updatedValues, rowIndex)
  }

  const changeCondition = (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | SelectChangeEvent,
    targetIndex: number,
    key: FieldKey,
  ) => {
    const newValue = event.target.value

    if (key === 'operator' && !isValidOperator(newValue)) return

    updateKeyValue(targetIndex, key, newValue)

    const isLastField = targetIndex === keyValues.length - 1
    const lastKeyValue = keyValues[keyValues.length - 1]
    const lastFieldFilled = lastKeyValue.key.trim() !== '' && lastKeyValue.value.trim() !== ''

    if (isLastField && lastFieldFilled) {
      const newId = `${typeId}-new-${rowIndex}-${Date.now()}`
      setKeyValues((prev) => [...prev, { id: newId, key: '', operator: '==', value: '' }])
    }
  }

  const removeCondition = (targetIndex: number) => {
    const next = keyValues.filter((_, i) => i !== targetIndex)
    setKeyValues(next.length > 0 ? next : [defaultKeyValue])
  }

  return (
    <Box>
      {keyValues.map((item, index) => (
        <Box key={item.id} sx={{ display: 'flex', marginTop: index !== 0 ? '5px' : '0px' }}>
          <TextField
            id={`key-${item.id}`}
            name={`key-${item.id}`}
            value={item.key}
            onChange={(e) => changeCondition(e, index, 'key')}
            size="small"
            placeholder={t('CustomerEdit.key')}
            sx={{
              width: '250px',
              marginLeft: '20px',
              marginRight: '10px',
              backgroundColor: '#fff',
              '& .MuiInputBase-input': { height: '15px', paddingLeft: '10px' },
            }}
            autoComplete="off"
          />

          <Select
            id={`operator-${item.id}`}
            name={`operator-${item.id}`}
            value={item.operator}
            onChange={(e) => changeCondition(e, index, 'operator')}
            sx={{
              height: '32px',
              width: '64px',
              minWidth: '64px',
              marginRight: '10px',
              backgroundColor: '#fff',
              '& .MuiSelect-select': { paddingLeft: '10px' },
            }}
          >
            {operators.map((op, idx) => (
              <MenuItem key={idx} value={op.value}>
                {op.label}
              </MenuItem>
            ))}
          </Select>

          <TextField
            id={`value-${item.id}`}
            name={`value-${item.id}`}
            value={item.value}
            onChange={(e) => changeCondition(e, index, 'value')}
            size="small"
            placeholder={t('CustomerEdit.value')}
            sx={{
              width: '150px',
              marginRight: '10px',
              backgroundColor: '#fff',
              '& .MuiInputBase-input': { height: '15px', paddingLeft: '10px' },
            }}
            autoComplete="off"
          />

          {keyValues.length > 1 && index !== keyValues.length - 1 && (
            <Button
              variant="contained"
              size="small"
              onClick={() => removeCondition(index)}
              sx={{ paddingTop: '2px', paddingBottom: '2px' }}
            >
              {t('Common.deleteButtonLabel')}
            </Button>
          )}
        </Box>
      ))}
    </Box>
  )
}
