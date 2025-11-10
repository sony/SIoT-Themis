import type { Customer, Prisma, Type } from 'schema/prisma/client'

export async function createType(
  prismaClient: Prisma.TransactionClient,
  parsedtypeKey: { id: string; type: string },
  temporaryCustomer: Customer,
) {
  const temporaryType: Type = await prismaClient.type.create({
    data: {
      customerId: temporaryCustomer.id,
      type: parsedtypeKey.type,
    },
  })
  return temporaryType
}
