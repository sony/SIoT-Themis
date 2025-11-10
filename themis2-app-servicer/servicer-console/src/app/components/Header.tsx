'use client'
import { AppBar, Button, Toolbar } from '@mui/material'
import { signOut } from 'next-auth/react'
import { useTranslations } from 'next-intl'

export function Header() {
  const t = useTranslations('Header')
  return (
    <AppBar position="static" sx={{ minWidth: '700px', width: '100%' }}>
      <Toolbar sx={{ display: 'flex', justifyContent: 'flex-end' }}>
        <Button color="inherit" onClick={() => signOut()}>
          {t('signOut')}
        </Button>
      </Toolbar>
    </AppBar>
  )
}
