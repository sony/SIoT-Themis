import type { Customer } from 'schema/prisma/client'

export type ServerActionResponse<T> =
  | {
      success: true
      data: T
    }
  | {
      success: false
      errors: Record<string, string>
    }

export type CustomerForList = Pick<Customer, 'id' | 'name'>
