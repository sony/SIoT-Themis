'use server'

import { Suspense } from 'react'

import { VisualizeTracker } from '@/app/(map)/components/VisualizeTracker'

export default async function MapPage() {
  return (
    <Suspense>
      <VisualizeTracker />
    </Suspense>
  )
}
