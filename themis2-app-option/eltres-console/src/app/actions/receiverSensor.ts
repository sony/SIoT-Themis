'use server'

import path from 'path'

import { getTranslations } from 'next-intl/server'

import type { ServerActionResponse } from '@/app/types/actions'

import { checkAuth } from '@/app/auth'
import { ParseCsvError } from '@/app/exceptions/ParseCsvError'
import { parseCsv } from '@/app/helpers/parseCsv'

export const updateReceiverSensor = async (
  _: ServerActionResponse,
  formData: FormData,
): Promise<ServerActionResponse> => {
  await checkAuth()
  const t = await getTranslations('validationError.server')
  const csvFile = formData.get('file')
  if (csvFile === null) {
    return {
      success: false,
      errors: {
        file: t('required'),
      },
    }
  }
  if (!(csvFile instanceof File)) {
    return {
      success: false,
      errors: {
        file: t('invalid'),
      },
    }
  }
  if (csvFile.size === 0) {
    return {
      success: false,
      errors: {
        file: t('required'),
      },
    }
  }
  if (path.extname(csvFile.name) !== '.csv' || csvFile.type !== 'text/csv') {
    return {
      success: false,
      errors: {
        file: t('extensionInvalid'),
      },
    }
  }
  const csvString = await csvFile.text()
  try {
    await parseCsv(csvString)
    console.log(csvString)
  } catch (error) {
    if (error instanceof ParseCsvError) {
      return {
        success: false,
        errors: {
          file: t('parseFailed'),
        },
      }
    }
    throw new Error()
  }
  return {
    success: true,
  }
}
