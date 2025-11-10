'use client'

import { useTranslations } from 'next-intl'

import { ErrorContent } from '@/app/components/ErrorContent'

export default function ErrorPage() {
  const t = useTranslations('ErrorPage')

  return <ErrorContent message={t('title')} />
}
