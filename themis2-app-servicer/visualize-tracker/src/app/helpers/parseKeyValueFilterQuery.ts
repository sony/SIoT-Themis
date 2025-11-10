import type { ConditionClause } from '@/app/types/condition'

import { isValidOperator } from '@/app/helpers/isValidOperator'
import searchMetrics from '@/data/searchMetrics.json'

const validSearchMetrics = searchMetrics.filter(
  (metric) => metric.field.startsWith('data.') || metric.field.startsWith('serviceTag.'),
)
const fieldRegexp = `(${validSearchMetrics.map((metric) => metric.field).join('|')})`
const regexp = new RegExp(`${fieldRegexp}(==|>=|<=|>|<)(.+)`)

export const parseKeyValueFilterQuery = (query: string): ConditionClause[] => {
  const conditionClauses: ConditionClause[] = query.split(';').flatMap((filter) => {
    const match = filter.match(regexp)

    if (!match) {
      return []
    }
    const [, field, operator, value] = match
    if (!isValidOperator(operator)) return []
    const excludedSingleQuoteValue = value.startsWith("'") && value.endsWith("'") ? value.slice(1, -1) : value
    return [
      {
        field: field,
        operator: operator,
        value: excludedSingleQuoteValue,
      },
    ]
  })
  return conditionClauses
}
