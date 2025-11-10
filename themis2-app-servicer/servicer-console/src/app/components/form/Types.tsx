import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown'
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp'
import {
  Box,
  Collapse,
  TextField,
  TableContainer,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Button,
  IconButton,
  Typography,
} from '@mui/material'
import { useTranslations } from 'next-intl'
import { useState } from 'react'
import * as React from 'react'

import type { Dispatch, SetStateAction } from 'react'

import { Condition } from '@/app/components/form/Condition'
import { Endpoint } from '@/app/components/form/Endpoint'
import { isInvalidType } from '@/app/helpers/isInvalidType'

type FieldKey = 'type' | 'types' | 'endpoint' | 'condition' | 'subscriptions'

type TypeData = {
  type: { type: string; id: string }
  subscriptions: { id: number; endpoint: string }[]
  conditions: { id: number; key: string; operator: string; value: string }[]
}

type TypeProps = {
  validationError: Partial<Record<FieldKey, string | null>>
  setValidationError: Dispatch<SetStateAction<Partial<Record<FieldKey, string | null>>>>
  typesData: {
    type: { type: string; id: string }
    subscriptions: { id: number; endpoint: string }[]
    conditions: { id: number; key: string; operator: string; value: string }[]
  }[]
  setTypesData: Dispatch<SetStateAction<TypeData[]>>
}

const Row = React.memo(function Row(props: {
  row: {
    type: { type: string; id: string }
    subscriptions: { id: number; endpoint: string }[]
    conditions: { id: number; key: string; operator: string; value: string }[]
  }
  rowIndex: number
  validationError: Partial<Record<FieldKey, string | null>>
  setValidationError: Dispatch<SetStateAction<Partial<Record<FieldKey, string | null>>>>
  subscriptions: { id: number; endpoint: string }[]
  open: boolean
  onToggle: () => void
  updateTypeData: (
    index: number,
    field: 'endpoint' | 'condition' | 'subscriptions',
    value: string | { endpoint: string }[] | { key: string; operator: string; value: string }[],
  ) => void
  removeType: () => void
  setTypesData: Dispatch<SetStateAction<TypeData[]>>
}) {
  const {
    row,
    rowIndex,
    validationError,
    setValidationError,
    subscriptions,
    open,
    onToggle,
    updateTypeData,
    removeType,
    setTypesData,
  } = props

  const t = useTranslations()

  const handleEndpointChange = (index: number, newValue: string) => {
    const updatedSubscriptions = subscriptions.map((s, i) => (i === index ? { ...s, endpoint: newValue } : s))

    updateTypeData(rowIndex, 'subscriptions', updatedSubscriptions)
  }

  const handleConditionChange = (updatedConditions: { key: string; operator: string; value: string }[]) => {
    const conditionsWithId = updatedConditions.map((condition, index) => ({
      ...condition,
      id: index,
    }))

    setTypesData((prevTypes) => prevTypes.map((t, i) => (i === rowIndex ? { ...t, conditions: conditionsWithId } : t)))
  }

  return (
    <React.Fragment>
      <TableRow sx={{ '& > *': { borderBottom: 'unset' } }}>
        <TableCell sx={{ paddingTop: '5px', paddingBottom: '5px' }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <IconButton aria-label="expand row" size="small" onClick={onToggle}>
                {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
              </IconButton>
              {row.type.type}
            </Box>
            <Button
              variant="contained"
              size="small"
              onClick={() => removeType()}
              sx={{ paddingTop: '2px', paddingBottom: '2px', align: 'right' }}
            >
              {t('Common.deleteButtonLabel')}
            </Button>
          </Box>
        </TableCell>
      </TableRow>
      <TableRow>
        <TableCell style={{ paddingBottom: 0, paddingTop: 0 }}>
          <Collapse in={open} timeout="auto">
            <Box sx={{ margin: 1 }}>
              <Table size="small">
                <TableBody>
                  <TableRow>
                    <TableCell sx={{ paddingTop: 0 }}>
                      <Typography style={{ paddingBottom: '2px' }}>{t('CustomerEdit.endpointInputLabel')}</Typography>
                      <Endpoint
                        values={subscriptions.map((s) => s.endpoint)}
                        validationError={validationError}
                        setValidationError={setValidationError}
                        onChange={handleEndpointChange}
                        rowIndex={rowIndex}
                        typeId={row.type.id}
                        subscriptions={row.subscriptions}
                      />
                      <Typography style={{ paddingBottom: '2px' }}>{t('CustomerEdit.conditionInputLabel')}</Typography>
                      <Condition
                        onChange={handleConditionChange}
                        rowIndex={rowIndex}
                        typeId={row.type.id}
                        conditions={row.conditions}
                      />
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </React.Fragment>
  )
})

export function Types({ validationError, setValidationError, typesData, setTypesData }: TypeProps) {
  const t = useTranslations()
  const TYPE_MAX_LENGTH = 250
  const [newType, setNewType] = useState<string>('')
  const [openRows, setOpenRows] = useState<Record<string, boolean>>({})

  const handleRowToggle = (row: string) => {
    setOpenRows((prevState) => ({
      ...prevState,
      [row]: !prevState[row],
    }))
  }

  const changeType = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValidationError({
      ...validationError,
      type: '',
    })
    setNewType(event.target.value)
  }

  const addType = () => {
    if (!newType.trim()) {
      setValidationError({
        ...validationError,
        type: t('ValidationError.Client.required', { field: t('CustomerEdit.typeInputLabel') }),
      })
      return
    }

    if (newType.length > TYPE_MAX_LENGTH) {
      setValidationError({
        ...validationError,
        type: t('ValidationError.Client.exceededLength', {
          field: t('CustomerEdit.typeInputLabel'),
          maxLength: TYPE_MAX_LENGTH,
        }),
      })
      return
    }

    if (isInvalidType(newType)) {
      setValidationError({
        ...validationError,
        type: t('ValidationError.Client.invalid', {
          field: t('CustomerEdit.typeInputLabel'),
        }),
      })
      return
    }

    if (typesData.some((t) => t.type.type === newType)) {
      // Check based on the 'type' field inside the object
      setValidationError({
        ...validationError,
        type: t('ValidationError.Server.typeIsNotUnique', { type: newType }),
      })
      return
    }

    // Ensure each new type has a subscriptions and conditions array (even if it's default values)
    setTypesData([
      ...typesData,
      {
        type: { type: newType, id: '' },
        subscriptions: [{ id: 0, endpoint: '' }],
        conditions: [{ id: 0, key: '', operator: '', value: '' }],
      },
    ])
    setValidationError({
      ...validationError,
      type: '',
    })
    setNewType('')
  }

  const updateTypeData = (
    index: number,
    field: 'endpoint' | 'condition' | 'subscriptions',
    value: string | { endpoint: string }[] | { key: string; operator: string; value: string }[],
  ) => {
    setTypesData((prevTypes) =>
      prevTypes.map((t, i) =>
        i === index
          ? {
              ...t,
              [field]:
                field === 'subscriptions' ? value : field === 'endpoint' ? [{ endpoint: value as string }] : value,
            }
          : t,
      ),
    )
  }

  const removeType = (index: number) => {
    setTypesData((prevTypes) => prevTypes.filter((_, i) => i !== index))
  }

  const typeInput = () => {
    return (
      <>
        <TextField
          id="typeInput"
          name="typeInput"
          label={t('CustomerEdit.typeInputLabel')}
          sx={{ width: '620px' }}
          size="small"
          slotProps={{
            inputLabel: {
              shrink: true,
            },
          }}
          value={newType}
          onChange={changeType}
          error={!!validationError.type}
          helperText={validationError.type}
        />

        <Button variant="contained" sx={{ width: '80px', height: '40px' }} onClick={addType}>
          {t('Common.addButtonLabel')}
        </Button>
      </>
    )
  }

  return (
    <>
      {typeInput()}
      <TableContainer
        sx={{ maxHeight: 590, border: 1, color: !!validationError.types ? 'red' : '', marginTop: '10px' }}
      >
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell key="type" align="center" size="small" sx={{ paddingTop: '2px', paddingBottom: '2px' }}>
                {t('CustomerEdit.typeInputLabel')}
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {typesData.map((typeData, index) => (
              <React.Fragment key={index}>
                <Row
                  key={typeData.type.id}
                  row={typeData}
                  rowIndex={index}
                  validationError={validationError}
                  setValidationError={setValidationError}
                  subscriptions={typeData.subscriptions}
                  open={openRows[typeData.type.type] || false}
                  onToggle={() => handleRowToggle(typeData.type.type)}
                  updateTypeData={updateTypeData}
                  removeType={() => removeType(index)}
                  setTypesData={setTypesData}
                />
              </React.Fragment>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </>
  )
}
