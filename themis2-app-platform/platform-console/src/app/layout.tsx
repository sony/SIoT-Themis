import { CssBaseline } from '@mui/material'
import { ThemeProvider } from '@mui/material/styles'
import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter'
import { NextIntlClientProvider } from 'next-intl'
import { getLocale, getMessages } from 'next-intl/server'

import ClientErrorHandler from './clientErrorHandler'
import { Header } from './components/Header'
import { SnackbarProvider } from './SnackbarProvider'

import type { Metadata } from 'next'

import { theme } from '@/theme'

export const metadata: Metadata = {
  title: 'Platform Console For Service',
  description: 'Themis2 platform console for service',
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
            <AppRouterCacheProvider>
              <ThemeProvider theme={theme}>
                <CssBaseline />
                {process.env.NODE_ENV === 'production' && <ClientErrorHandler />}
                <SnackbarProvider>
                  <Header />
                  {children}
                </SnackbarProvider>
              </ThemeProvider>
            </AppRouterCacheProvider>
          </div>
        </body>
      </NextIntlClientProvider>
    </html>
  )
}
