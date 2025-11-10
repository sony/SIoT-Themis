import { readdir } from 'fs/promises'
import { join } from 'path'

import { headers } from 'next/headers'
import { getRequestConfig } from 'next-intl/server'

export default getRequestConfig(async () => {
  const headersList = headers()
  const browserAcceptLanguage = (await headersList).get('accept-language') || ''

  const languages = browserAcceptLanguage
    .toLowerCase()
    .split(',')
    .map((lang) => {
      const [language, qValue] = lang.trim().split(';q=')
      return {
        language: language.trim(),
        priority: qValue ? parseFloat(qValue) : 1.0,
      }
    })
    .sort((a, b) => b.priority - a.priority)

  const messagesDir = join(process.cwd(), 'messages')
  const messageFiles = await readdir(messagesDir)
  const availableLocales = messageFiles
    .filter((file) => file.endsWith('.json'))
    .map((file) => file.replace('.json', ''))

  let locale = 'en'

  for (const lang of languages) {
    const fullLanguageCode = lang.language.toLowerCase()

    if (availableLocales.includes(fullLanguageCode)) {
      locale = fullLanguageCode
      break
    }

    const baseLanguageCode = lang.language.split('-')[0]

    if (availableLocales.includes(baseLanguageCode)) {
      locale = baseLanguageCode
      break
    }
  }

  return {
    locale,
    messages: (await import(`../../messages/${locale}.json`)).default,
  }
})
