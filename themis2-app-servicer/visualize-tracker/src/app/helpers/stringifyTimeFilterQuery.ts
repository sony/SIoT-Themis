import type { ConditionClause, ConditionOperator } from '@/app/types/condition'

export const stringifyTimeFilterQuery = (conditionClauses: ConditionClause[]): string | undefined => {
  const validOperators: ConditionOperator[] = ['>=', '<=']
  const timestampClauses = conditionClauses.filter((clause) => clause.field === 'timestamp')

  if (timestampClauses.length > 2) {
    return undefined
  }
  if (timestampClauses.filter((clause) => clause.operator === validOperators[0]).length > 1) {
    return undefined
  }
  if (timestampClauses.filter((clause) => clause.operator === validOperators[1]).length > 1) {
    return undefined
  }
  if (timestampClauses.filter((clause) => !validOperators.includes(clause.operator)).length > 0) {
    return undefined
  }
  const query = timestampClauses
    .filter((clause) => {
      return !isNaN(new Date(clause.value).getTime()) && clause.field === 'timestamp'
    })
    .map((clause) => {
      return `${clause.field}${clause.operator}${clause.value}`
    })
    .join(';')
  if (!query) {
    return undefined
  }
  return query
}
