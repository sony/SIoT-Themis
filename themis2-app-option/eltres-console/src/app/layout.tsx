import { CssBaseline, ThemeProvider } from '@mui/material'
import { NextIntlClientProvider } from 'next-intl'
import { getLocale, getMessages } from 'next-intl/server'

import ClientErrorHandler from './clientErrorHandler'
import { Header } from './components/Header'

import type { Metadata } from 'next'

import { SnackbarProvider } from '@/app/SnackbarProvider'
import { theme } from '@/theme'

export const metadata: Metadata = {
  title: 'ELTRES Console',
  description: 'Console for ELTRES receiver',
}

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  const locale = await getLocale()
  const messages = await getMessages()
  return (
    <html lang={locale}>
      <NextIntlClientProvider messages={messages}>
        <body>
          <div dir="auto">
            <ThemeProvider theme={theme}>
              <NextIntlClientProvider messages={messages}>
                <CssBaseline />
                <Header />
                {process.env.NODE_ENV === 'production' && <ClientErrorHandler />}
                <SnackbarProvider>{children}</SnackbarProvider>
              </NextIntlClientProvider>
            </ThemeProvider>
          </div>
        </body>
      </NextIntlClientProvider>
    </html>
  )
}
