import type { Condition } from 'schema/prisma/client'

export type ConditionClause = Pick<Condition, 'key' | 'operator' | 'value'>
