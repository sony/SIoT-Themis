'use server'
import { getTranslations } from 'next-intl/server'

import type { ServerActionResponse } from '../types/serverActionResponse'
import type { GeoExpression } from '@/app/types/circle'
import type { ConditionClause } from '@/app/types/condition'

import { createGeoExpressionParameter } from '@/app/helpers/createGeoExpressionParameter'
import { stringifyKeyValueFilterQuery } from '@/app/helpers/stringifyKeyValueFilterQuery'

const backendApiKey = process.env.BACKEND_API_KEY as string
const realtimeNotificationApiOrigin = process.env.REALTIME_NOTIFICATION_API_ORIGIN as string
const visualizeTrackerOrigin = process.env.VISUALIZE_TRACKER_ORIGIN as string

export type SubscriptionId = {
  id: string
}

type NotifyConditionExpression = {
  georel?: string
  geometry?: string
  coords?: string
  q?: string
}

type NotifyCondition = {
  expression: NotifyConditionExpression
}

export const createNotification = async (
  socketId: string,
  type: string,
  conditionClauses: ConditionClause[],
  geoExpression: GeoExpression,
): Promise<ServerActionResponse<string>> => {
  const t = await getTranslations('notify')

  const body: { [prop: string]: string | NotifyCondition } = {
    type: type,
    url: `${visualizeTrackerOrigin}/api/notify/${socketId}`,
  }

  const expression: NotifyConditionExpression = {}

  const geoExpressionParameters = createGeoExpressionParameter(geoExpression)
  if (geoExpressionParameters.length > 0) expression.geometry = 'point'
  geoExpressionParameters.forEach((geoExpressionParameter) => {
    expression[geoExpressionParameter[0]] = geoExpressionParameter[1]
  })

  if (conditionClauses.length > 0) {
    expression.q = stringifyKeyValueFilterQuery(conditionClauses)
  }

  if (Object.keys(expression).length > 0) {
    body.condition = {
      expression: expression,
    }
  }

  const response = await fetch(`${realtimeNotificationApiOrigin}/notify`, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      authorization: backendApiKey,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    return {
      success: false,
      errors: {
        name: t('realtimeDisplayFailed'),
      },
    }
  }

  const subscriptionId: SubscriptionId = await response.json()
  return {
    success: true,
    data: subscriptionId.id,
  }
}

export const deleteNotification = async (subscriptionId: string): Promise<ServerActionResponse<null>> => {
  const t = await getTranslations('notify')
  const response = await fetch(`${realtimeNotificationApiOrigin}/notify/${subscriptionId}`, {
    method: 'DELETE',
    headers: {
      authorization: backendApiKey,
    },
  })

  if (!response.ok) {
    return {
      success: false,
      errors: {
        name: t('realtimeStopFailed'),
      },
    }
  }

  return {
    success: true,
    data: null,
  }
}
