'use client'

import { Box, TextField, Button, Typography, Switch, FormControlLabel } from '@mui/material'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useState, useContext, useEffect, useActionState } from 'react'

import type { ServerActionResponse } from '@/types/actions'
import type { Servicer } from 'schema/prisma/client/postgres'

import { deleteServicer } from '@/app/actions/servicers'
import { ApiKey } from '@/app/components/form/ApiKey'
import { ConfirmableButton } from '@/app/components/form/ConfirmableButton'
import { PrincipalIds } from '@/app/components/form/PrincipalIds'
import { ServicerName } from '@/app/components/form/ServicerName'
import { isEmpty } from '@/app/helpers/isEmpty'
import { isValidUrl } from '@/app/helpers/isValidUrl'
import { SnackbarContext } from '@/app/SnackbarProvider'

type ValidationError = Partial<Record<string, string | null>>

type ServicerFormProps = {
  servicer?: Servicer
  submitAction: (_: ServerActionResponse<Servicer>, formData: FormData) => Promise<ServerActionResponse<Servicer>>
}

export function ServicerForm({ servicer, submitAction }: ServicerFormProps) {
  const t = useTranslations()
  const router = useRouter()

  const { setAlert } = useContext(SnackbarContext)

  const [validationError, setValidationError] = useState<ValidationError>({})
  const [urlValue, setUrlValue] = useState<string>(servicer?.url || '')
  const [isRealtimeEnabled, setIsRealtimeEnabled] = useState<boolean>(servicer?.analyze || false)

  const initialState: ServerActionResponse<Servicer> = {
    success: false,
    errors: {},
  }

  const [state, formAction] = useActionState(submitAction, initialState)

  useEffect(() => {
    if (state.success) {
      setAlert({
        severity: 'success',
        message: t('servicer.successSaved', { name: state.data.name }),
      })
      router.push(`/servicers/${state.data.id}`)
    } else if (!state.success) {
      if (isEmpty(state.errors)) return
      const errorMessage = Object.values(state.errors).join('\n')
      setAlert({
        severity: 'error',
        message: errorMessage,
      })
      setValidationError((validationError) => ({ ...validationError, ...state.errors }))
    }
  }, [state, router, setAlert, t])

  const onDeleteDialogOk = async () => {
    const deleteResult = await deleteServicer(servicer!.id)
    if (!deleteResult.success) {
      if (isEmpty(deleteResult.errors)) return
      const errorMessage = Object.values(deleteResult.errors).join('\n')
      setAlert({
        severity: 'error',
        message: errorMessage,
      })
      return
    }
    setAlert({
      severity: 'success',
      message: t('servicer.successDeleted', { name: servicer!.name }),
    })
    router.push('/')
  }

  const handleUrlChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newUrl = event.target.value
    setUrlValue(newUrl)

    if (validationError.url) {
      setValidationError((prev) => {
        const newErrors = { ...prev }
        delete newErrors.url
        return newErrors
      })
    }

    if (newUrl.trim() && !isValidUrl(newUrl)) {
      setValidationError((prev) => ({
        ...prev,
        url: t('validationError.client.invalid', { field: 'URL' }),
      }))
    }

    if (!newUrl.trim()) {
      setIsRealtimeEnabled(false)
    }
  }

  const apiEndpointInputField = () => {
    return (
      <TextField
        id="url"
        name="url"
        type="url"
        label={t('servicer.apiEndpointInputLabel')}
        fullWidth
        size="small"
        value={urlValue}
        onChange={handleUrlChange}
        slotProps={{
          inputLabel: {
            shrink: true,
          },
        }}
        error={!!validationError.url}
      />
    )
  }

  return (
    <Box sx={{ width: '700px', margin: '0 auto', marginTop: '10px' }}>
      <Box sx={{ marginBottom: '20px' }}>
        <Link href="/">
          <Button variant="text" size="small">
            {t('servicer.backButtonLabel')}
          </Button>
        </Link>
      </Box>

      <form action={formAction}>
        <Box sx={{ marginBottom: '15px' }}>
          <ServicerName
            value={servicer?.name}
            validationError={validationError}
            setValidationError={setValidationError}
          />
        </Box>

        <Box sx={{ marginBottom: '10px' }}>
          <ApiKey value={servicer?.apiKey} disabled={!servicer} />
        </Box>

        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <Typography variant="body1">{t('servicer.realtimeLabel')}</Typography>
          <Box
            sx={{
              marginInlineStart: 'auto',
              paddingInlineEnd: '10px',
              height: '20px',
              display: 'flex',
              alignItems: 'center',
            }}
          >
            <FormControlLabel
              control={
                <Switch
                  checked={isRealtimeEnabled}
                  onChange={(e) => setIsRealtimeEnabled(e.target.checked)}
                  disabled={!urlValue.trim()}
                  size="medium"
                />
              }
              label=""
              sx={{ margin: 0, height: '20px' }}
            />
          </Box>
        </Box>
        <input type="hidden" name="analyze" value={isRealtimeEnabled.toString()} />
        <Box sx={{ marginBottom: '10px' }}>{apiEndpointInputField()}</Box>

        <Box>
          <PrincipalIds
            originPrincipalIds={servicer?.principalIds}
            validationError={validationError}
            setValidationError={setValidationError}
          />
        </Box>

        <Box sx={{ marginTop: '10px', textAlign: 'end' }}>
          <Button variant="contained" type="submit" sx={{ marginInlineEnd: servicer ? '10px' : '' }}>
            {t('common.saveButtonLabel')}
          </Button>
          {servicer && (
            <ConfirmableButton
              title={t('servicer.confirmDeleteTitle')}
              content={t('servicer.confirmDeleteContent', {
                servicer: t('servicer.servicer'),
                name: servicer.name,
              })}
              okLabel={t('common.agreeButtonLabel')}
              cancelLabel={t('common.denyButtonLabel')}
              onContinue={onDeleteDialogOk}
            >
              {t('common.deleteButtonLabel')}
            </ConfirmableButton>
          )}
        </Box>
      </form>
    </Box>
  )
}
