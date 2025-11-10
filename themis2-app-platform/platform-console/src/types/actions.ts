import type { Servicer } from 'schema/prisma/client/postgres'

export type ServerActionResponse<T> =
  | {
      success: true
      data: T
    }
  | {
      success: false
      errors: Record<string, string>
    }

export type ServicerForList = Pick<Servicer, 'id' | 'name'>

export type PrincipalIdCsvRow = {
  principalId: string
}
