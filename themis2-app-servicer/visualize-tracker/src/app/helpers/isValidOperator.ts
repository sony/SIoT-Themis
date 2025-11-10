import type { ConditionOperator } from '@/app/types/condition'

import { operators } from '@/app/constants/operators'

export const isValidOperator = (arg: string): arg is ConditionOperator => {
  return operators.includes(arg as ConditionOperator)
}
