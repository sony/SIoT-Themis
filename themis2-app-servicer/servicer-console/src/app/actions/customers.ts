'use server'

import crypto from 'crypto'

import { revalidatePath } from 'next/cache'
import { getTranslations } from 'next-intl/server'
import { PrismaClient, Prisma } from 'schema/prisma/client'

import type { CustomerForList, ServerActionResponse } from '@/types/actions'
import type { Condition, Customer, Subscription, Type } from 'schema/prisma/client'

import { checkAuth } from '@/app/auth'
import { createConditions } from '@/app/helpers/createConditions'
import { createEndpoints } from '@/app/helpers/createEndpoints'
import { createType } from '@/app/helpers/createType'

type NotifyConditionExpression = {
  q?: string
}

type NotifyCondition = {
  expression?: NotifyConditionExpression
  attrs?: string[]
}

const prismaClient = new PrismaClient()
const notificationEndpointPath = '/notify/'
const notificationEndpoint = process.env.REALTIME_NOTIFICATION_API_ENDPOINT + notificationEndpointPath
const notificationApiKey = process.env.REALTIME_NOTIFICATION_API_KEY

const generateApiKey = () => {
  const keySize = 32
  return crypto.randomBytes(keySize).toString('base64').substring(0, keySize)
}

export const getAllCustomers = async (): Promise<ServerActionResponse<CustomerForList[]>> => {
  await checkAuth()
  const customers = await prismaClient.customer.findMany({
    select: {
      id: true,
      name: true,
    },
    orderBy: [{ id: 'asc' }],
  })
  return {
    success: true,
    data: customers,
  }
}

type CustomerWithTypeAndRelations = Prisma.CustomerGetPayload<{
  include: { types: { include: { conditions: true; subscriptions: true } } }
}>

export const getCustomer = async (id: number): Promise<ServerActionResponse<CustomerWithTypeAndRelations>> => {
  await checkAuth()
  const t = await getTranslations('ValidationError.Server')
  try {
    const customer: CustomerWithTypeAndRelations | null = await prismaClient.customer.findUnique({
      where: { id },
      include: {
        types: {
          include: {
            conditions: true,
            subscriptions: true,
          },
          orderBy: [{ id: 'asc' }],
        },
      },
    })

    if (!customer) {
      return {
        success: false,
        errors: {
          customer: t('customerNotFound'),
        },
      }
    }

    return {
      success: true,
      data: customer,
    }
  } catch (e) {
    console.log(e)
    return {
      success: false,
      errors: {
        customer: t('customerGetFailed'),
      },
    }
  }
}

export const createCustomer = async (
  _: ServerActionResponse<Customer>,
  formData: FormData,
): Promise<ServerActionResponse<Customer>> => {
  await checkAuth()
  const t = await getTranslations('ValidationError.Server')

  if (notificationEndpoint === notificationEndpointPath) {
    return {
      success: false,
      errors: {
        customer: t('notificationEndpointNotFound'),
      },
    }
  }

  const name = formData.get('name')?.toString()
  if (!name) {
    return {
      success: false,
      errors: {
        name: t('required'),
      },
    }
  }

  const apiKey = generateApiKey()
  if (!apiKey) {
    return {
      success: false,
      errors: {
        apiKey: t('apiKeyCreateFailed'),
      },
    }
  }

  try {
    // Start transaction
    const customer = await prismaClient.$transaction(async (tx: Prisma.TransactionClient) => {
      // Create customer data record
      const temporaryCustomer: Customer = await tx.customer.create({
        data: {
          name,
          apiKey,
        },
      })

      const typeKeys = Array.from(formData.keys()).filter((k) => k.includes('type-'))
      const endpointKeys = Array.from(formData.keys()).filter((k) => k.includes('endpoint-'))
      const conditionKeys = Array.from(formData.keys()).filter((k) => k.includes('key-'))

      // Create type data records
      for (const typeKey of typeKeys) {
        const typeId = typeKey.substring(typeKey.lastIndexOf('-') + 1, typeKey.length).replace('new', '')
        const typeKeyValue = formData.get(typeKey)
        if (typeKeyValue && typeof typeKeyValue === 'string') {
          try {
            const parsedtypeKey = JSON.parse(typeKeyValue) as { id: string; type: string }
            const temporaryType: Type = await createType(tx, parsedtypeKey, temporaryCustomer)

            await createConditions(tx, conditionKeys, formData, typeId, temporaryType)

            // Get all conditions from the current type
            const currentTypeConditions: Condition[] = await tx.condition.findMany({
              where: { typeId: temporaryType.id },
            })

            const expression: NotifyConditionExpression = {}

            // Assign call current conditions to the expression query
            if (currentTypeConditions.length > 0) {
              expression.q = currentTypeConditions
                .map((condition: Condition) => `${condition.key}${condition.operator}${condition.value}`)
                .join(';')
            }

            await createEndpoints(
              tx,
              endpointKeys,
              formData,
              typeId,
              parsedtypeKey,
              expression,
              notificationEndpoint,
              notificationApiKey,
              temporaryType,
            )
          } catch (e) {
            console.error(e)
            throw new Error(t('typeCreateFailed'))
          }
        }
      }

      const data: Customer = temporaryCustomer
      return {
        success: true,
        data,
      }
    })

    if (!customer.data) {
      return {
        success: false,
        errors: {
          name: t('customerCreateFailed'),
        },
      }
    }
    revalidatePath('/customers/list')
    const data: Customer = customer.data
    return {
      success: true,
      data,
    }
  } catch (e) {
    console.log(e)
    if (e instanceof Prisma.PrismaClientKnownRequestError) {
      if (e.code === 'P2002') {
        return {
          success: false,
          errors: {
            name: t('customerNameIsNotUnique', { name: name }),
          },
        }
      }
    }
    return {
      success: false,
      errors: {
        name: t('customerCreateFailed'),
      },
    }
  }
}

export const updateCustomer = async (
  _: ServerActionResponse<Customer>,
  id: number,
  formData: FormData,
): Promise<ServerActionResponse<Customer>> => {
  await checkAuth()
  const t = await getTranslations('ValidationError.Server')

  if (notificationEndpoint === notificationEndpointPath) {
    return {
      success: false,
      errors: {
        customer: t('notificationEndpointNotFound'),
      },
    }
  }

  const name = formData.get('name')?.toString()
  if (!name) {
    return {
      success: false,
      errors: {
        name: t('required'),
      },
    }
  }

  const targetCustomer = await prismaClient.customer.findUnique({
    where: { id },
  })
  if (!targetCustomer) throw new Error()
  try {
    // Start transaction
    const customer = await prismaClient.$transaction(async (tx: Prisma.TransactionClient) => {
      // Update customer data record
      const temporaryCustomer: Customer = await tx.customer.update({
        where: { id },
        data: {
          name: name,
        },
      })

      // Get current customer type data
      const temporaryCustomerTypes: Type[] = await tx.type.findMany({
        where: { customerId: temporaryCustomer.id },
      })
      // Delete type data
      for (const temporaryCustomerType of temporaryCustomerTypes) {
        // Type was removed from form
        if (!formData.get(`type-${temporaryCustomerType.id}`)) {
          const temporarySubscriptions: Subscription[] = await tx.subscription.findMany({
            where: { typeId: temporaryCustomerType.id },
          })

          for (const temporarySubscription of temporarySubscriptions) {
            // Delete the orion notification setting associated with the current subscription
            const response = await fetch(`${notificationEndpoint}${temporarySubscription.subscriptionId}`, {
              method: 'DELETE',
              headers: {
                Authorization: notificationApiKey || '',
                // eslint-disable-next-line @typescript-eslint/naming-convention
                'Content-Type': 'application/json',
              },
            })

            if (!response.ok) {
              throw new Error(`HTTP error! Status: ${response.status}`)
            }

            // Delete the subscription from the database
            await tx.subscription.delete({
              where: { id: temporarySubscription.id },
            })
          }

          await tx.type.delete({
            where: {
              id: temporaryCustomerType.id,
            },
          })
        }
      }

      const typeKeys = Array.from(formData.keys()).filter((k) => k.includes('type-'))
      const endpointKeys = Array.from(formData.keys()).filter((k) => k.includes('endpoint-'))
      const conditionKeys = Array.from(formData.keys()).filter((k) => k.includes('key-'))

      // Insert or update type data
      for (const typeKey of typeKeys) {
        if (typeKey.startsWith('type-')) {
          let isTypeInsert = true
          const typeId = typeKey.substring(typeKey.lastIndexOf('-') + 1, typeKey.length).replace('new', '')

          const typeKeyValue = formData.get(typeKey)

          if (typeKeyValue && typeof typeKeyValue === 'string') {
            try {
              const parsedtypeKey = JSON.parse(typeKeyValue) as { id: string; type: string }

              for (const temporaryCustomerType of temporaryCustomerTypes) {
                // A form value exists for the current type data
                if (parseInt(typeId) === temporaryCustomerType.id) {
                  isTypeInsert = false
                  // Update type data
                  await tx.type.update({
                    where: {
                      customerId: temporaryCustomer.id,
                      id: temporaryCustomerType.id,
                    },
                    data: {
                      customerId: temporaryCustomer.id,
                      id: temporaryCustomerType.id,
                      type: parsedtypeKey.type,
                    },
                  })

                  // Hold all active condition IDs
                  const currentConditionKeysIds = []

                  // Iterate over all condition keys and ensure all conditions for this type are inserted or updated
                  for (const conditionKey of conditionKeys) {
                    currentConditionKeysIds.push(conditionKey.split('-')[2])
                    if (conditionKey.startsWith(`key-`) && formData.get(conditionKey) !== '') {
                      const conditionTypeId = conditionKey.split('-')[1]
                      const conditionkeyId = conditionKey.split('-')[2]
                      const operatorKey = `operator-${conditionKey.substring(4, conditionKey.length)}`
                      const valueKey = `value-${conditionKey.substring(4, conditionKey.length)}`
                      if (formData.get(conditionKey) !== '' && formData.get(valueKey) !== '') {
                        // Condition doesn't include "new" or "0" (condition for update)
                        if (conditionkeyId !== 'new' && conditionkeyId !== '0' && conditionTypeId === typeId) {
                          if (formData.get(conditionKey) !== '' && formData.get(valueKey) !== '') {
                            await tx.condition.update({
                              where: { id: parseInt(conditionkeyId), typeId: temporaryCustomerType.id },
                              data: {
                                key: (formData.get(conditionKey) ?? '') as string,
                                operator: (formData.get(operatorKey) ?? '') as string,
                                value: (formData.get(valueKey) ?? '') as string,
                              },
                            })
                          }
                        } else {
                          // Condition includes "new" or "0" (condition for insertion)
                          if ((conditionkeyId === 'new' || conditionkeyId === '0') && conditionTypeId === typeId) {
                            const temporaryCondition: Condition = await tx.condition.create({
                              data: {
                                typeId: temporaryCustomerType.id,
                                key: (formData.get(conditionKey) ?? '') as string,
                                operator: (formData.get(operatorKey) ?? '') as string,
                                value: (formData.get(valueKey) ?? '') as string,
                              },
                            })
                            currentConditionKeysIds.push(temporaryCondition.id)
                          }
                        }
                      }
                    }
                  }

                  // Filter "new" IDs out of the current form condition ID list and change numbered IDs to ints
                  const validConditionIds = currentConditionKeysIds
                    .filter((id) => /^\d+$/.test(String(id)))
                    .map((id) => parseInt(String(id)))

                  // Delete any conditons that are no longer in the form
                  await tx.condition.deleteMany({
                    where: {
                      typeId: temporaryCustomerType.id,
                      id: {
                        notIn: validConditionIds,
                      },
                    },
                  })

                  // Get all conditions from the current type
                  const currentTypeConditions: Condition[] = await tx.condition.findMany({
                    where: { typeId: temporaryCustomerType.id },
                  })

                  const expression: NotifyConditionExpression = {}

                  // Assign call current conditions to the expression query
                  if (currentTypeConditions.length > 0) {
                    expression.q = currentTypeConditions
                      .map((condition: Condition) => `${condition.key}${condition.operator}${condition.value}`)
                      .join(';')
                  }

                  // Hold all active endpoint IDs
                  const currentEndpointKeysIds = []

                  // Iterate over all endpoint keys and ensure all endpoints for this type are inserted or updated
                  for (const endpointKey of endpointKeys) {
                    if (endpointKey.startsWith(`endpoint-`) && formData.get(endpointKey) !== '') {
                      const endpoint = formData.get(endpointKey)?.toString()
                      const endpointKeyTypeId = endpointKey.split('-')[1]
                      const endpointKeyId = endpointKey.split('-')[2]
                      // Endpoint doesn't include "new" or "0" (endpoint for update)
                      if (endpointKeyId !== 'new' && endpointKeyId !== '0' && endpointKeyTypeId === typeId) {
                        const endpointSubscriptionId = parseInt(endpointKeyId)
                        if (endpoint) {
                          const body: { [prop: string]: string | NotifyCondition } = {
                            url: endpoint,
                            type: parsedtypeKey.type,
                            condition: {
                              attrs: [],
                            },
                          }
                          if (Object.keys(expression).length > 0) {
                            body.condition = {
                              expression: expression,
                            }
                          }
                          // Get endpoint's subscriptionId
                          const temporarySubscription: Subscription | null = await tx.subscription.findUnique({
                            where: { id: endpointSubscriptionId },
                          })
                          if (temporarySubscription) {
                            // Update subscription information
                            const response = await fetch(
                              `${notificationEndpoint}${temporarySubscription.subscriptionId}`,
                              {
                                method: 'PATCH',
                                headers: {
                                  Authorization: notificationApiKey || '',
                                  // eslint-disable-next-line @typescript-eslint/naming-convention
                                  'Content-Type': 'application/json',
                                },
                                body: JSON.stringify(body),
                              },
                            )

                            if (!response.ok) {
                              throw new Error(`HTTP error! Status: ${response.status}`)
                            }

                            // Update the subscription in the database
                            await tx.subscription.update({
                              where: { id: endpointSubscriptionId },
                              data: {
                                endpoint: endpoint,
                              },
                            })
                            currentEndpointKeysIds.push(endpointSubscriptionId)
                          }
                        }
                      } else {
                        // Endpoint includes "new" or "0" (endpoint for insertion)
                        if ((endpointKeyId === 'new' || endpointKeyId === '0') && endpointKeyTypeId === typeId) {
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
                            const response = await fetch(`${notificationEndpoint}`, {
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
                            const temporarySubscription: Subscription = await tx.subscription.create({
                              data: {
                                typeId: temporaryCustomerType.id,
                                subscriptionId: responseData.id,
                                endpoint: endpoint,
                              },
                            })
                            currentEndpointKeysIds.push(temporarySubscription.id)
                          }
                        }
                      }
                    }
                  }

                  // Filter "new" IDs out of the current form condition ID list and change numbered IDs to ints
                  const validEndpointIds = currentEndpointKeysIds
                    .filter((id) => /^\d+$/.test(String(id)))
                    .map((id) => parseInt(String(id)))

                  // Get all "subscriptionId" values for all endpoints that aren't in validEndpointIds to use later in notification deletion
                  const deletedSubscriptions = await tx.subscription.findMany({
                    where: {
                      typeId: temporaryCustomerType.id,
                      id: {
                        notIn: validEndpointIds,
                      },
                    },
                    select: {
                      subscriptionId: true,
                    },
                  })

                  // Delete any conditons that are no longer in the form
                  await tx.subscription.deleteMany({
                    where: {
                      typeId: temporaryCustomerType.id,
                      id: {
                        notIn: validEndpointIds,
                      },
                    },
                  })

                  // Remove the orion subscription for each endpoint that was deleted in the form
                  for (const deletedSubscription of deletedSubscriptions) {
                    // Delete the orion notification setting associated with the current subscription
                    const response = await fetch(`${notificationEndpoint}${deletedSubscription.subscriptionId}`, {
                      method: 'DELETE',
                      headers: {
                        Authorization: notificationApiKey || '',
                        // eslint-disable-next-line @typescript-eslint/naming-convention
                        'Content-Type': 'application/json',
                      },
                    })
                    if (!response.ok && response.status !== 404) {
                      throw new Error(`HTTP error! Status: ${response.status}`)
                    }
                  }
                }
              }

              // Insert new type data and related conditions/endpoints
              if (isTypeInsert === true) {
                const temporaryType: Type = await createType(tx, parsedtypeKey, temporaryCustomer)

                // Insert new type conditions
                await createConditions(tx, conditionKeys, formData, typeId, temporaryType)

                // Get all conditions from the current type
                const currentTypeConditions: Condition[] = await tx.condition.findMany({
                  where: { typeId: temporaryType.id },
                })

                const expression: NotifyConditionExpression = {}

                // Assign call current conditions to the expression query
                if (currentTypeConditions.length > 0) {
                  expression.q = currentTypeConditions
                    .map((condition: Condition) => `${condition.key}${condition.operator}${condition.value}`)
                    .join(';')
                }

                // Insert new type endpoints
                await createEndpoints(
                  tx,
                  endpointKeys,
                  formData,
                  typeId,
                  parsedtypeKey,
                  expression,
                  notificationEndpoint,
                  notificationApiKey,
                  temporaryType,
                )
              }
            } catch (e) {
              console.error(e)
              throw new Error(t('typeCreateFailed'))
            }
          }
        }
      }

      const data: Customer = temporaryCustomer
      return {
        success: true,
        data,
      }
    })

    if (!customer.data) {
      return {
        success: false,
        errors: {
          name: t('customerUpdateFailed'),
        },
      }
    }
    revalidatePath('/customers/list')
    revalidatePath(`/customers/${id}`)
    const data: Customer = customer.data
    return {
      success: true,
      data,
    }
  } catch (e) {
    console.error(e)
    if (e instanceof Prisma.PrismaClientKnownRequestError) {
      if (e.code === 'P2002') {
        return {
          success: false,
          errors: {
            name: t('customerNameIsNotUnique', { name: name }),
          },
        }
      }
    }
    return {
      success: false,
      errors: {
        name: t('customerUpdateFailed'),
      },
    }
  }
}

export const deleteCustomer = async (id: number): Promise<ServerActionResponse<void>> => {
  await checkAuth()
  const t = await getTranslations('ValidationError.Server')

  if (notificationEndpoint === notificationEndpointPath) {
    return {
      success: false,
      errors: {
        customer: t('notificationEndpointNotFound'),
      },
    }
  }

  try {
    // Start transaction
    await prismaClient.$transaction(async (tx: Prisma.TransactionClient) => {
      // Get all types associated with the selected customer
      const temporaryTypes: Type[] = await tx.type.findMany({
        where: { customerId: id },
      })
      // Loop through each type
      for (const type of temporaryTypes) {
        // Get all subscriptions associated with the current type
        const temporarySubscriptions: Subscription[] = await tx.subscription.findMany({
          where: { typeId: type.id },
        })
        // Loop through each subscription
        for (const subscription of temporarySubscriptions) {
          // Delete the orion notification setting associated with the current subscription
          const response = await fetch(`${notificationEndpoint}${subscription.subscriptionId}`, {
            method: 'DELETE',
            headers: {
              Authorization: notificationApiKey || '',
              // eslint-disable-next-line @typescript-eslint/naming-convention
              'Content-Type': 'application/json',
            },
          })

          if (!response.ok && response.status !== 404) {
            throw new Error(`HTTP error! Status: ${response.status}`)
          }
        }
      }
      // Delete the selected customer (Cascade Delete)
      await tx.customer.delete({
        where: { id },
      })
    })
    revalidatePath('/customers/list')
    return {
      success: true,
      data: undefined,
    }
  } catch (e) {
    console.log(e)
    return {
      success: false,
      errors: {
        name: t('customerDeleteFailed'),
      },
    }
  }
}
