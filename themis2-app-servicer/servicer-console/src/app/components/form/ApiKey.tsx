import { TextField, Button } from '@mui/material'
import { useTranslations } from 'next-intl'
import { useContext } from 'react'

import { SnackbarContext } from '@/app/SnackbarProvider'

type ApiKeyProps = {
  value: string | null | undefined
  disabled: boolean
}

export function ApiKey({ value, disabled }: ApiKeyProps) {
  const t = useTranslations()
  const { setAlert } = useContext(SnackbarContext)

  const copyApiKey = async () => {
    await navigator.clipboard.writeText(value!)
    setAlert({
      severity: 'success',
      message: t('CustomerEdit.copiedApiKey'),
    })
  }

  return (
    <>
      <TextField
        id="apiKey"
        label={t('CustomerEdit.apiKeyInputLabel')}
        disabled
        sx={{ width: '620px' }}
        size="small"
        defaultValue={value}
        slotProps={{
          inputLabel: {
            shrink: true,
          },
        }}
      />
      <Button
        variant="contained"
        sx={{ width: '80px', height: '40px' }}
        disabled={disabled}
        onClick={() => copyApiKey()}
      >
        {t('Common.copyButtonLabel')}
      </Button>
    </>
  )
}
