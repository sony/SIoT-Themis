import path from 'path'

import {
  Box,
  TextField,
  TableContainer,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Button,
  Typography,
  Select,
  MenuItem,
} from '@mui/material'
import { useTranslations } from 'next-intl'
import { useState, useEffect } from 'react'

import type { SelectChangeEvent } from '@mui/material/Select'
import type { Dispatch, SetStateAction } from 'react'

import { Csv } from '@/app/components/form/Csv'

type FieldKey = 'principalId' | 'principalIds' | 'file'

type PrincipalIdsProps = {
  originPrincipalIds: number[] | string[] | undefined
  validationError: Partial<Record<FieldKey, string | null>>
  setValidationError: Dispatch<SetStateAction<Partial<Record<FieldKey, string | null>>>>
}

export function PrincipalIds({ originPrincipalIds, validationError, setValidationError }: PrincipalIdsProps) {
  const t = useTranslations()
  const [updateType, setUpdateType] = useState<string>('manual')
  const [principalIds, setPrincipalIds] = useState<(number | string)[]>(originPrincipalIds ?? [])
  const [newPrincipalId, setNewPrincipalId] = useState<string>('')

  useEffect(() => {
    setPrincipalIds(originPrincipalIds ?? [])
  }, [originPrincipalIds])

  const changePrincipalId = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValidationError({ ...validationError, principalId: null })
    setNewPrincipalId(event.target.value)
  }

  const addPrincipalId = () => {
    const newValidationError: Partial<Record<FieldKey, string | null>> = {
      principalIds: null,
      principalId: null,
    }

    if (newPrincipalId.length === 0) {
      newValidationError.principalId = t('validationError.client.required', {
        field: t('servicer.principalId'),
      })
    }

    setValidationError({ ...validationError, ...newValidationError })
    if (Object.values(newValidationError).some((x) => x)) return

    setPrincipalIds((principalIds) => [...principalIds, newPrincipalId])
    setNewPrincipalId('')
  }

  const removePrincipalId = (id: number | string) => {
    setPrincipalIds((principalIds) => principalIds.filter((principalId) => principalId !== id))
  }

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

  const selectUpdateType = (event: SelectChangeEvent) => {
    setValidationError({
      ...validationError,
      principalIds: null,
      principalId: null,
    })
    setUpdateType(event.target.value)
  }

  const manualPrincipalIdsInput = () => {
    return (
      <>
        <TextField
          id="principalId"
          sx={{ width: '540px' }}
          size="small"
          type="text"
          value={newPrincipalId}
          onChange={changePrincipalId}
          error={!!validationError.principalId}
          helperText={validationError.principalId}
        />

        <Button variant="contained" sx={{ width: '80px', height: '40px', flexShrink: 0 }} onClick={addPrincipalId}>
          {t('common.addButtonLabel')}
        </Button>
      </>
    )
  }

  const csvPrincipalIdsInput = () => {
    return (
      <Box sx={{ marginTop: '1px' }}>
        <Csv
          id="file"
          name="file"
          onChange={changeFile}
          helperText={t('servicer.overwritePrincipalIds')}
          errorMessage={validationError.file}
        />
      </Box>
    )
  }

  return (
    <>
      <Typography variant="body1">{t('servicer.permissionLabel')}</Typography>
      <TableContainer sx={{ maxHeight: 260, border: 1, color: !!validationError.principalIds ? 'red' : '' }}>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell
                key="principalId"
                align="center"
                size="small"
                colSpan={2}
                sx={{ paddingTop: '2px', paddingBottom: '2px' }}
              >
                {t('servicer.principalId')}
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {principalIds.map((principalId, index) => (
              <TableRow key={index}>
                <TableCell key="principalId" size="small" align="left" sx={{ paddingTop: '4px', paddingBottom: '4px' }}>
                  {principalId}
                  <input type="hidden" name="principalIds" value={principalId} />
                </TableCell>
                <TableCell
                  key="deleteButton"
                  align="center"
                  size="small"
                  sx={{ width: '100px', paddingTop: '4px', paddingBottom: '4px' }}
                >
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => removePrincipalId(principalId)}
                    sx={{ paddingTop: '2px', paddingBottom: '2px' }}
                  >
                    {t('common.deleteButtonLabel')}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Box sx={{ marginTop: '10px', marginBottom: '20px', display: 'flex', alignItems: 'flex-start' }}>
        <Select name="updateType" value={updateType} size="small" onChange={selectUpdateType} sx={{ flexShrink: 0 }}>
          <MenuItem value="manual">{t('servicer.manual')}</MenuItem>
          <MenuItem value="upload">{t('servicer.csv')}</MenuItem>
        </Select>

        {updateType === 'upload' ? csvPrincipalIdsInput() : manualPrincipalIdsInput()}
      </Box>
    </>
  )
}
