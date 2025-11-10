import type { ConditionClause } from '@/app/types/condition'

import searchMetrics from '@/data/searchMetrics.json'

const validSearchMetrics = searchMetrics.filter(
  (metric) => metric.field.startsWith('data.') || metric.field.startsWith('serviceTag.'),
)

export const stringifyKeyValueFilterQuery = (conditionClauses: ConditionClause[]): string | undefined => {
  const keyValueClauses = conditionClauses.filter((clause) =>
    validSearchMetrics.find((metric) => clause.field === metric.field),
  )

  if (keyValueClauses.length > Number(process.env.NEXT_PUBLIC_SEARCH_KEY_VALUE_MAX_LENGTH!)) {
    return undefined
  }
  const query = keyValueClauses
    .map((clause) => {
      const targetMetric = validSearchMetrics.find((metric) => metric.field === clause.field)!
      const value = targetMetric.type === 'string' ? `'${clause.value}'` : clause.value
      return `${clause.field}${clause.operator}${value}`
    })
    .join(';')
  if (!query) {
    return undefined
  }
  return query
}
