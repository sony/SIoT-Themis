import { notFound } from 'next/navigation'

import type { ServerActionResponse } from '@/types/actions'
import type { Servicer } from 'schema/prisma/client/postgres'

import { getServicer, updateServicer } from '@/app/actions/servicers'
import { ServicerForm } from '@/app/servicers/components/ServicerForm'

export default async function ServicerUpdate({ params }: { params: Promise<{ id: string }> }) {
  const result = await getServicer(Number((await params).id))

  if (!result.success) {
    notFound()
  }

  const wrappedUpdateServicer = async (
    _: ServerActionResponse<Servicer>,
    formData: FormData,
  ): Promise<ServerActionResponse<Servicer>> => {
    'use server'
    return updateServicer(_, result.data.id, formData)
  }

  return <ServicerForm servicer={result.data} submitAction={wrappedUpdateServicer} />
}
