import { CssBaseline } from '@mui/material'
import { ThemeProvider } from '@mui/material/styles'
import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter'
import { NextIntlClientProvider } from 'next-intl'
import { getLocale, getMessages } from 'next-intl/server'

import type { Metadata, Viewport } from 'next'

import ClientErrorHandler from '@/app/clientErrorHandler'
import { PreventZoom } from '@/app/components/PreventZoom'
import { SnackbarProvider } from '@/app/SnackbarProvider'
import { theme } from '@/theme'

export const metadata: Metadata = {
  title: 'Sample Visualize Tracker',
  description: 'Sample visualize tracker for themis2',
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
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
      <body>
        <PreventZoom>
          <AppRouterCacheProvider>
            <NextIntlClientProvider messages={messages}>
              <ThemeProvider theme={theme}>
                <CssBaseline />
                {process.env.NODE_ENV === 'production' && <ClientErrorHandler />}
                <SnackbarProvider>{children}</SnackbarProvider>
              </ThemeProvider>
            </NextIntlClientProvider>
          </AppRouterCacheProvider>
        </PreventZoom>
      </body>
    </html>
  )
}
