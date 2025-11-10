'use server'

import path from 'path'

import { revalidatePath } from 'next/cache'
import { getTranslations } from 'next-intl/server'
import { PrismaClient as PostgresClient, Prisma } from 'schema/prisma/client/postgres'

import type { ServerActionResponse, ServicerForList, PrincipalIdCsvRow } from '@/types/actions'
import type { Servicer } from 'schema/prisma/client/postgres'

import { checkAuth } from '@/app/auth'
import { parseCsv } from '@/app/helpers/parseCsv'
import { ParseCsvError } from '@/exceptions/ParseCsvError'
import { KongClient } from '@/kong/client'

const postgresClient = new PostgresClient()
const kong = new KongClient(process.env.KONG_GATEWAY_ORIGIN!)

const orionEndpoint = process.env.ORION_ENDPOINT!
const fiwareService = process.env.FIWARE_SERVICE!

const validatePrincipalIdsUniqueness = async (
  principalIds: string[],
  excludeServicerId?: number,
): Promise<string[]> => {
  if (principalIds.length === 0) {
    return []
  }

  const whereClause = excludeServicerId ? { id: { not: excludeServicerId } } : undefined
  const existingServicers = await postgresClient.servicer.findMany({
    where: whereClause,
    select: {
      id: true,
      principalIds: true,
    },
  })

  const allExistingPrincipalIds = existingServicers.flatMap(
    (servicer: { principalIds: string[] }) => servicer.principalIds,
  )
  const duplicatePrincipalIds = principalIds.filter((id: string) => allExistingPrincipalIds.includes(id))

  return duplicatePrincipalIds
}

export const getAllServicers = async (): Promise<ServerActionResponse<ServicerForList[]>> => {
  await checkAuth()

  const servicers = await postgresClient.servicer.findMany({
    select: {
      id: true,
      name: true,
    },
    orderBy: [{ id: 'asc' }],
  })
  return {
    success: true,
    data: servicers,
  }
}

export const getServicer = async (id: number): Promise<ServerActionResponse<Servicer>> => {
  await checkAuth()

  const t = await getTranslations('validationError.server')
  const servicer = await postgresClient.servicer.findUnique({
    where: { id },
  })

  if (!servicer) {
    return {
      success: false,
      errors: {
        service: t('servicerNotFound'),
      },
    }
  }
  return {
    success: true,
    data: servicer,
  }
}

export const createServicer = async (
  _: ServerActionResponse<Servicer>,
  formData: FormData,
): Promise<ServerActionResponse<Servicer>> => {
  await checkAuth()

  const t = await getTranslations()

  const cygnusEndpoint = process.env.CYGNUS_ENDPOINT!

  const name = formData.get('name')?.toString()
  if (!name) {
    return {
      success: false,
      errors: {
        name: t('validationError.server.required'),
      },
    }
  }

  const url = formData.get('url')?.toString() || null
  if (url && !URL.canParse(url)) {
    return {
      success: false,
      errors: {
        url: t('validationError.server.invalid'),
      },
    }
  }

  const analyze = formData.get('analyze')?.toString() === 'true'

  const updateType = formData.get('updateType')?.toString()

  let principalIds: string[] = []
  if (updateType === 'upload') {
    const csvFile = formData.get('file')
    if (csvFile === null) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.required'),
        },
      }
    }
    if (!(csvFile instanceof File)) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.invalid'),
        },
      }
    }
    if (csvFile.size === 0) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.required'),
        },
      }
    }
    if (path.extname(csvFile.name) !== '.csv' || csvFile.type !== 'text/csv') {
      return {
        success: false,
        errors: {
          file: t('validationError.server.extensionInvalid'),
        },
      }
    }

    const csvString = await csvFile.text()
    try {
      const parsedResult = await parseCsv(csvString)
      if (parsedResult.errors.length > 0) {
        return {
          success: false,
          errors: {
            file: t('validationError.server.parseFailed'),
          },
        }
      }
      const rawPrincipalIds: PrincipalIdCsvRow[] = parsedResult.data
      principalIds = Array.from(new Set(rawPrincipalIds.map((ids) => ids.principalId)))
      if (principalIds.length === 0) {
        return {
          success: false,
          errors: {
            file: t('validationError.server.invalid'),
          },
        }
      }
    } catch (error) {
      if (error instanceof ParseCsvError) {
        return {
          success: false,
          errors: {
            file: error.message,
          },
        }
      }
      throw new Error()
    }
  } else if (updateType === 'manual') {
    const rawPrincipalIds = formData.getAll('principalIds') as string[]
    principalIds = Array.from(new Set(rawPrincipalIds))
    if (principalIds.length === 0) {
      return {
        success: false,
        errors: {
          principalIds: t('validationError.server.required'),
        },
      }
    }
  }

  // Check for duplicate Principal IDs across all servicers
  const duplicatePrincipalIds = await validatePrincipalIdsUniqueness(principalIds)
  if (duplicatePrincipalIds.length > 0) {
    const duplicateIdsMessage = duplicatePrincipalIds.join('\n')
    return {
      success: false,
      errors: {
        principalIds: `${t('validationError.server.principalIdNotUnique')}\n${duplicateIdsMessage}`,
      },
    }
  }

  let temporaryServicer: Servicer | undefined
  try {
    const servicer = await postgresClient.$transaction(async (tx: Prisma.TransactionClient) => {
      temporaryServicer = await tx.servicer.create({
        data: {
          name,
          url,
          analyze,
          principalIds,
        },
      })

      const apiKey = await kong.createApiKey(temporaryServicer.id.toString())

      try {
        await fetch(`${orionEndpoint}/v2/subscriptions`, {
          method: 'POST',
          headers: {
            // eslint-disable-next-line @typescript-eslint/naming-convention
            'Content-Type': 'application/json',
            // eslint-disable-next-line @typescript-eslint/naming-convention
            'Fiware-Service': fiwareService,
            // eslint-disable-next-line @typescript-eslint/naming-convention
            'Fiware-ServicePath': `/servicers/${temporaryServicer.id}`,
          },
          body: JSON.stringify({
            description: `Notify Cygnus of all changes for ${temporaryServicer.id}`,
            subject: {
              entities: [{ idPattern: '.*' }],
            },
            notification: {
              http: {
                url: `${cygnusEndpoint}/notify`,
              },
            },
          }),
        })
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown fetch error'
        throw new Error(
          t('validationError.server.orionCreateFailed', {
            error: errorMessage,
          }),
        )
      }

      return await tx.servicer.update({
        where: { id: temporaryServicer.id },
        data: {
          apiKey: apiKey,
        },
      })
    })
    revalidatePath('/')

    return {
      success: true,
      data: servicer,
    }
  } catch (e) {
    console.error(e)
    if (e instanceof Prisma.PrismaClientKnownRequestError) {
      if (e.code === 'P2002') {
        return {
          success: false,
          errors: {
            apiKey: t('validationError.server.servicerNameIsNotUnique', {
              servicer: t('servicer.servicer'),
            }),
          },
        }
      }
    }
    if (temporaryServicer?.id) {
      await kong.deleteServicer(`${temporaryServicer.id}`)
    }
    return {
      success: false,
      errors: {
        apiKey:
          e instanceof Error
            ? t('validationError.server.subscriptionCreateFailed')
            : t('validationError.server.apiKeyCreateFailed'),
      },
    }
  }
}
export const updateServicer = async (
  _: ServerActionResponse<Servicer>,
  id: number,
  formData: FormData,
): Promise<ServerActionResponse<Servicer>> => {
  await checkAuth()

  const t = await getTranslations()

  const name = formData.get('name')?.toString()
  if (!name) {
    return {
      success: false,
      errors: {
        name: t('validationError.server.required'),
      },
    }
  }

  const url = formData.get('url')?.toString() || null
  if (url && !URL.canParse(url)) {
    return {
      success: false,
      errors: {
        url: t('validationError.server.invalid'),
      },
    }
  }

  const analyze = formData.get('analyze')?.toString() === 'true'

  const updateType = formData.get('updateType')?.toString()

  let principalIds: string[] = []
  if (updateType === 'upload') {
    const csvFile = formData.get('file')
    if (csvFile === null) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.required'),
        },
      }
    }
    if (!(csvFile instanceof File)) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.invalid'),
        },
      }
    }
    if (csvFile.size === 0) {
      return {
        success: false,
        errors: {
          file: t('validationError.server.required'),
        },
      }
    }
    if (path.extname(csvFile.name) !== '.csv' || csvFile.type !== 'text/csv') {
      return {
        success: false,
        errors: {
          file: t('validationError.server.extensionInvalid'),
        },
      }
    }

    const csvString = await csvFile.text()
    try {
      const parsedResult = await parseCsv(csvString)
      if (parsedResult.errors.length > 0) {
        return {
          success: false,
          errors: {
            file: t('validationError.server.parseFailed'),
          },
        }
      }
      const rawPrincipalIds: PrincipalIdCsvRow[] = parsedResult.data
      principalIds = Array.from(new Set(rawPrincipalIds.map((ids) => ids.principalId)))
      if (principalIds.length === 0) {
        return {
          success: false,
          errors: {
            file: t('validationError.server.invalid'),
          },
        }
      }
    } catch (error) {
      if (error instanceof ParseCsvError) {
        return {
          success: false,
          errors: {
            file: error.message,
          },
        }
      }
      throw new Error()
    }
  } else if (updateType === 'manual') {
    const rawPrincipalIds = formData.getAll('principalIds') as string[]
    principalIds = Array.from(new Set(rawPrincipalIds))
    if (principalIds.length === 0) {
      return {
        success: false,
        errors: {
          principalIds: t('validationError.server.required'),
        },
      }
    }
  }

  // Check for duplicate Principal IDs across all servicers (excluding current servicer)
  const duplicatePrincipalIds = await validatePrincipalIdsUniqueness(principalIds, id)
  if (duplicatePrincipalIds.length > 0) {
    const duplicateIdsMessage = duplicatePrincipalIds.join('\n')
    return {
      success: false,
      errors: {
        principalIds: `${t('validationError.server.principalIdNotUnique')}\n${duplicateIdsMessage}`,
      },
    }
  }

  try {
    const servicer = await postgresClient.servicer.update({
      where: { id },
      data: {
        name,
        url,
        analyze,
        principalIds,
      },
    })
    revalidatePath('/')
    revalidatePath(`/servicers/${id}`)

    return {
      success: true,
      data: servicer,
    }
  } catch (e) {
    console.error(e)
    if (e instanceof Prisma.PrismaClientKnownRequestError) {
      if (e.code === 'P2002') {
        return {
          success: false,
          errors: {
            apiKey: t('validationError.server.servicerNameIsNotUnique', {
              servicer: t('servicer.servicer'),
            }),
          },
        }
      }
    }
    throw new Error()
  }
}

export const deleteServicer = async (id: number): Promise<ServerActionResponse<void>> => {
  await checkAuth()

  const t = await getTranslations('validationError.server')

  // CygnusへのサブスクリプションをOrionから削除
  const subscriptionsResponse = await fetch(`${orionEndpoint}/v2/subscriptions`, {
    headers: {
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'Fiware-Service': fiwareService,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      'Fiware-ServicePath': `/servicers/${id}`,
    },
  })
  if (!subscriptionsResponse.ok) throw new Error()

  let failuresCount = 0
  const subscriptions = await subscriptionsResponse.json()
  for (const subscription of subscriptions) {
    const response = await fetch(`${orionEndpoint}/v2/subscriptions/${subscription.id}`, {
      method: 'DELETE',
      headers: {
        // eslint-disable-next-line @typescript-eslint/naming-convention
        'Fiware-Service': fiwareService,
        // eslint-disable-next-line @typescript-eslint/naming-convention
        'Fiware-ServicePath': `/servicers/${id}`,
      },
    })
    if (!response.ok) failuresCount++
  }

  if (failuresCount > 0) {
    return {
      success: false,
      errors: {
        subscription: t('subscriptionDeleteFailed', {
          count: subscriptions.length,
          failedCount: failuresCount,
        }),
      },
    }
  }

  await kong.deleteServicer(`${id}`)

  await postgresClient.servicer.delete({
    where: { id },
  })
  revalidatePath('/')
  return {
    success: true,
    data: undefined,
  }
}
