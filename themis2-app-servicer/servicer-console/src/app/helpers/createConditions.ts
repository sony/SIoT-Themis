import type { Prisma, Type } from 'schema/prisma/client'

export async function createConditions(
  prismaClient: Prisma.TransactionClient,
  conditionKeys: string[],
  formData: FormData,
  typeId: string,
  temporaryType: Type,
) {
  // Iterate over all condition keys and ensure they are inserted to this type
  for (const conditionKey of conditionKeys) {
    if (
      // conditionKeys that start with "key-" are formatted like "key-34-58-0-0" (key-TypeID-ConditionID-rowIndex-index)
      conditionKey.startsWith(`key-`) &&
      // '0' conditions are the default first condition in a row, 'new' conditions are all conditions added automatically
      (conditionKey.split('-')[2] === 'new' || conditionKey.split('-')[2] === '0') &&
      formData.get(conditionKey) !== '' &&
      conditionKey.split('-')[3] === typeId
    ) {
      const operatorKey = `operator-${conditionKey.substring(4, conditionKey.length)}`
      const valueKey = `value-${conditionKey.substring(4, conditionKey.length)}`
      // Create condition data records if valueKey has a value, otherwise do nothing
      if (formData.get(valueKey) !== '') {
        await prismaClient.condition.create({
          data: {
            typeId: temporaryType.id,
            key: (formData.get(conditionKey) ?? '') as string,
            operator: (formData.get(operatorKey) ?? '') as string,
            value: (formData.get(valueKey) ?? '') as string,
          },
        })
      }
    }
  }
}
