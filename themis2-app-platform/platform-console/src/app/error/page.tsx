'use client'

import { useTranslations } from 'next-intl'

import { ErrorContent } from '@/app/components/ErrorContent'

export default function Error() {
  const t = useTranslations('errorPage')

  return <ErrorContent message={t('title')} />
}
