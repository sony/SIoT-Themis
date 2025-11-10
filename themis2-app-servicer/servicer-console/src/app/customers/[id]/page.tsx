import { notFound } from 'next/navigation'

import { CustomerForm } from '../components/CustomersForm'

import type { ServerActionResponse } from '@/types/actions'
import type { Customer } from 'schema/prisma/client/'

import { getCustomer, updateCustomer } from '@/app/actions/customers'

export default async function CustomerUpdate({ params }: { params: Promise<{ id: string }> }) {
  const result = await getCustomer(Number((await params).id))
  if (!result.success) {
    notFound()
  }

  const wrappedUpdateCustomer = async (
    _: ServerActionResponse<Customer>,
    formData: FormData,
  ): Promise<ServerActionResponse<Customer>> => {
    'use server'
    return updateCustomer(_, result.data.id, formData)
  }

  return <CustomerForm customer={result.data} submitAction={wrappedUpdateCustomer} />
}
