import type { operators } from '@/app/constants/operators'

export type ConditionOperator = (typeof operators)[number]

export type ConditionClause = {
  field: string
  operator: ConditionOperator
  value: string
}
