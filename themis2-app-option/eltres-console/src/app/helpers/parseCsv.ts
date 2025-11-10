import { getTranslations } from 'next-intl/server'
import Papa from 'papaparse'

import { ParseCsvError } from '@/app/exceptions/ParseCsvError'

export const parseCsv = async (csvString: string): Promise<string> => {
  const t = await getTranslations('validationError.server')
  return new Promise(async (resolve, reject) => {
    Papa.parse(csvString, {
      complete: (results: Papa.ParseResult<{ eltresReceiverId: string; lfourId: string }>) => {
        const formattedData = results.data.map((row) => Object.values(row).join(',')).join('\n')
        resolve(formattedData)
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
