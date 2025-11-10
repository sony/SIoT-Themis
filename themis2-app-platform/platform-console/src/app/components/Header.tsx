'use client'
import { AppBar, Button, Toolbar } from '@mui/material'
import Link from 'next/link'
import { signOut } from 'next-auth/react'
import { useTranslations } from 'next-intl'

export function Header() {
  const t = useTranslations('header')

  return (
    <AppBar position="static" sx={{ minWidth: '700px', width: '100%' }}>
      <Toolbar sx={{ display: 'flex', justifyContent: 'space-between' }}>
        <Link href="/">
          <Button sx={{ color: '#FFF' }}>{t('home')}</Button>
        </Link>
        <Button color="inherit" onClick={() => signOut()}>
          {t('signOut')}
        </Button>
      </Toolbar>
    </AppBar>
  )
}
