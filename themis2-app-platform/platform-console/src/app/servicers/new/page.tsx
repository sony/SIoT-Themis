'use client'

import { createServicer } from '@/app/actions/servicers'
import { ServicerForm } from '@/app/servicers/components/ServicerForm'

export default function ServicersNew() {
  return <ServicerForm submitAction={createServicer} />
}
