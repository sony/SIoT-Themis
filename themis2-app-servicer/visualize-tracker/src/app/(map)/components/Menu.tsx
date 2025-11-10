'use client'
import { Tabs, Tab, Drawer, Toolbar } from '@mui/material'
import { useTranslations } from 'next-intl'
import { useState } from 'react'

import { DisplayPanel } from '@/app/(map)/components/DisplayPanel'
import { SearchPanel } from '@/app/(map)/components/SearchPanel'

type MenuProps = {
  isMenuOpen: boolean
  onClose: () => void
}

export function Menu({ isMenuOpen, onClose }: MenuProps) {
  const [value, setValue] = useState<number>(0)

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue)
  }
  const t = useTranslations('Tab')
  return (
    <Drawer
      anchor="right"
      open={isMenuOpen}
      onClose={onClose}
      ModalProps={{
        keepMounted: true,
        slotProps: {
          backdrop: {
            invisible: true,
          },
        },
      }}
      sx={{
        '& .MuiDrawer-paper': {
          width: '360px',
          height: '100vh',
        },
      }}
    >
      <Toolbar
        sx={{
          width: 360,
          height: '56px',
        }}
      />
      <Tabs value={value} onChange={handleChange} sx={{ marginRight: '110px' }}>
        <Tab label={t('display')} />
        <Tab label={t('search')} />
      </Tabs>
      <DisplayPanel panelValue={value} />
      <SearchPanel panelValue={value} />
    </Drawer>
  )
}
