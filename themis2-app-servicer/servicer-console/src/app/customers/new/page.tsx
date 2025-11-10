'use client'

import { createCustomer } from '@/app/actions/customers'
import { CustomerForm } from '@/app/customers/components/CustomersForm'

export default function CustomerCreate() {
  return <CustomerForm submitAction={createCustomer} />
}
