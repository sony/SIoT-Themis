'use client'

import { useTranslations } from 'next-intl'

import { ErrorContent } from '@/app/components/ErrorContent'

export default function NotFound() {
  const t = useTranslations('NotFound')

  return <ErrorContent message={t('pageNotFound')} />
}
