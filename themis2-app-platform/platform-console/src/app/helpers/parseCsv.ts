import { getTranslations } from 'next-intl/server'
import Papa from 'papaparse'

import type { PrincipalIdCsvRow } from '@/types/actions'

import { ParseCsvError } from '@/exceptions/ParseCsvError'

export const parseCsv = async (csvString: string): Promise<Papa.ParseResult<PrincipalIdCsvRow>> => {
  const t = await getTranslations('validationError.server')
  return new Promise(async (resolve, reject) => {
    Papa.parse(csvString, {
      complete: (results: Papa.ParseResult<PrincipalIdCsvRow>) => {
        resolve(results)
      },
      error: () => {
        reject(new ParseCsvError(t('parseFailed')))
      },
      header: true,
      skipEmptyLines: 'greedy',
      delimiter: ',',
    })
  })
}
