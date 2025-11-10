'use client'

import { useTranslations } from 'next-intl'

import { ErrorContent } from '@/app/(map)/components/ErrorContent'

export default function NotFound() {
  const t = useTranslations('errorPage')

  return <ErrorContent message={t('pageNotFound')} />
}
