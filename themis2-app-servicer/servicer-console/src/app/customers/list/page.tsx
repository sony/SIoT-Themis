import { Box, TableContainer, Table, TableHead, TableBody, TableRow, TableCell, Button } from '@mui/material'
import Link from 'next/link'
import { getTranslations } from 'next-intl/server'

import { getAllCustomers } from '@/app/actions/customers'

export default async function CustomersList() {
  const t = await getTranslations()
  const result = await getAllCustomers()
  const customers = result.success ? result.data : []

  return (
    <Box sx={{ width: '700px', margin: '0 auto', marginTop: '10px' }}>
      <TableContainer sx={{ marginTop: '20px', maxHeight: 450, border: 1 }}>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell key="name" align="center">
                {t('CustomersList.tableHeader')}
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {customers.map((customer) => (
              <TableRow key={customer.id}>
                <TableCell key="name" align="left" sx={{ p: 0 }}>
                  <Link href={`/customers/${customer.id}`}>
                    <Button fullWidth style={{ justifyContent: 'flex-start', textTransform: 'none' }} sx={{ p: 2 }}>
                      {customer['name']}
                    </Button>
                  </Link>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Box sx={{ marginTop: '10px', textAlign: 'right' }}>
        <Link href="/customers/new">
          <Button variant="contained">{t('Common.addButtonLabel')}</Button>
        </Link>
      </Box>
    </Box>
  )
}
