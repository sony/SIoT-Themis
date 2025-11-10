import { Box, TableContainer, Table, TableHead, TableBody, TableRow, TableCell, Button } from '@mui/material'
import Link from 'next/link'
import { getTranslations } from 'next-intl/server'

import { getAllServicers } from '@/app/actions/servicers'

export default async function ServicersList() {
  const t = await getTranslations()
  const result = await getAllServicers()
  const servicers = result.success ? result.data : []

  return (
    <Box sx={{ width: '700px', margin: '0 auto', marginTop: '10px' }}>
      <TableContainer sx={{ marginTop: '50px', maxHeight: 450, border: 1 }}>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell key="name" align="center">
                {t('servicer.servicerName')}
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {servicers.map((servicer) => (
              <TableRow key={servicer.id}>
                <TableCell key="name" align="left" sx={{ p: 0 }}>
                  <Link href={`/servicers/${servicer.id}`}>
                    <Button fullWidth style={{ justifyContent: 'flex-start', textTransform: 'none' }} sx={{ p: 2 }}>
                      {servicer['name']}
                    </Button>
                  </Link>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Box sx={{ marginTop: '20px', textAlign: 'right' }}>
        <Link href="/servicers/new">
          <Button variant="contained">{t('common.addButtonLabel')}</Button>
        </Link>
      </Box>
    </Box>
  )
}
