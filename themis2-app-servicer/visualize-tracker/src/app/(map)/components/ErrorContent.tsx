import { Box, Button, Typography } from '@mui/material'
import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'

type ErrorContentProps = {
  message: string
}

export function ErrorContent({ message }: ErrorContentProps) {
  const router = useRouter()
  const t = useTranslations('common')

  const backHomePage = () => {
    router.push('/')
  }

  return (
    <Box
      sx={{
        width: '350px',
        margin: '0 auto',
        marginTop: '80px',
        textAlign: 'center',
        border: '0.5px solid #007FFF',
        borderRadius: '5px',
        padding: '30px 0px',
      }}
    >
      <Typography variant="h6" marginBottom="30px" sx={{ fontWeight: 'bold' }}>
        {message}
      </Typography>
      <Button variant="contained" onClick={backHomePage}>
        {t('backHomeLabel')}
      </Button>
    </Box>
  )
}
