'use server'
import { getTranslations } from 'next-intl/server'

import type { ServerActionResponse } from '../types/serverActionResponse'
import type { GeoExpression } from '@/app/types/circle'
import type { ConditionClause } from '@/app/types/condition'
import type { Ship } from '@/app/types/ship'

import { createGeoExpressionParameter } from '@/app/helpers/createGeoExpressionParameter'
import { stringifyKeyValueFilterQuery } from '@/app/helpers/stringifyKeyValueFilterQuery'
import { stringifyTimeFilterQuery } from '@/app/helpers/stringifyTimeFilterQuery'

export const search = async (
  type: string,
  conditionClauses: ConditionClause[],
  geoExpression: GeoExpression,
): Promise<ServerActionResponse<Ship[]>> => {
  const t = await getTranslations('error')
  const backendApiKey = process.env.BACKEND_API_KEY as string
  const dataControllerApiOrigin = process.env.DATA_CONTROLLER_API_ORIGIN as string

  const query = new URLSearchParams({
    type: type,
  })

  if (conditionClauses.length > 0) {
    const queries: string[] = []
    const timeFilterQuery = stringifyTimeFilterQuery(conditionClauses)
    if (timeFilterQuery) queries.push(timeFilterQuery)
    const keyValueFilterQuery = stringifyKeyValueFilterQuery(conditionClauses)
    if (keyValueFilterQuery) queries.push(keyValueFilterQuery)
    const conditionQueryExpression = queries.join(';')
    query.set('q', conditionQueryExpression)
  }

  const geoExpressionParameters = createGeoExpressionParameter(geoExpression)
  if (geoExpressionParameters.length > 0) {
    query.set('geoattr', 'location')
    query.set('geometry', 'point')
  }
  geoExpressionParameters.forEach((geoExpressionParameter) => {
    query.set(geoExpressionParameter[0], geoExpressionParameter[1])
  })

  const response = await fetch(`${dataControllerApiOrigin}/search?${query}`, {
    headers: {
      authorization: backendApiKey,
    },
    cache: 'no-store',
  })

  if (!response.ok) {
    return {
      success: false,
      errors: {
        name: t('iconLocationsAcquisitionFailed'),
      },
    }
  }

  const ships: Ship[] = (await response.json()) as Ship[]
  return {
    success: true,
    data: ships,
  }
}
