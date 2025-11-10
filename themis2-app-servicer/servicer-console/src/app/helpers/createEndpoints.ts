import type { Prisma, Type } from 'schema/prisma/client'

type NotifyConditionExpression = {
  q?: string
}

type NotifyCondition = {
  expression: NotifyConditionExpression
}

export async function createEndpoints(
  prismaClient: Prisma.TransactionClient,
  endpointKeys: string[],
  formData: FormData,
  typeId: string,
  parsedtypeKey: { id: string; type: string },
  expression: NotifyConditionExpression,
  notificationEndpoint: string,
  notificationApiKey: string | undefined,
  temporaryType: Type,
) {
  // Iterate over all endpoint keys and ensure they are inserted to this type
  for (const endpointKey of endpointKeys) {
    if (
      // endpointKeys are formatted like "endpoint-34-58-0-0" (endpoint-TypeID-SubscriptionID-rowIndex-index)
      endpointKey.startsWith(`endpoint-`) &&
      // '0' endpoints are the default first endpoint in a row, 'new' endpoints are all endpoints added automatically
      (endpointKey.split('-')[2] === 'new' || endpointKey.split('-')[2] === '0') &&
      formData.get(endpointKey) !== '' &&
      endpointKey.split('-')[3] === typeId
    ) {
      const endpoint = formData.get(endpointKey)?.toString()

      // Create subscription data records if endpoint has a value, otherwise do nothing
      if (endpoint) {
        const body: { [prop: string]: string | NotifyCondition } = {
          url: endpoint,
          type: parsedtypeKey.type,
        }
        if (Object.keys(expression).length > 0) {
          body.condition = {
            expression: expression,
          }
        }
        // Add a subscription notification for the endpoint
        const response = await fetch(notificationEndpoint, {
          method: 'POST',
          headers: {
            Authorization: notificationApiKey || '',
            // eslint-disable-next-line @typescript-eslint/naming-convention
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
        })

        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`)
        }

        const responseData = await response.json()

        // Create the subscription in the database
        await prismaClient.subscription.create({
          data: {
            typeId: temporaryType.id,
            subscriptionId: responseData.id,
            endpoint: endpoint,
          },
        })
      }
    }
  }
}
