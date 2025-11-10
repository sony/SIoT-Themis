import type { ConditionClause, ConditionOperator } from '@/app/types/condition'

export const parseTimeFilterQuery = (query: string): ConditionClause[] => {
  const conditionClauses: ConditionClause[] = query.split(';').flatMap((filter) => {
    const match = filter.match(/timestamp(>=|<=)(.+)/)
    if (!match) {
      return []
    }
    const [, operator, value] = match
    if (isNaN(new Date(value).getTime())) {
      return []
    }
    return [
      {
        field: 'timestamp',
        operator: operator as ConditionOperator,
        value: value,
      },
    ]
  })
  if (conditionClauses.length > 2) {
    return []
  }
  const validOperators: ConditionOperator[] = ['>=', '<=']
  if (conditionClauses.filter((clause) => clause.operator === validOperators[0]).length > 1) {
    return []
  }
  if (conditionClauses.filter((clause) => clause.operator === validOperators[1]).length > 1) {
    return []
  }
  return conditionClauses
}
