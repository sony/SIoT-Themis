import { Close, Menu } from '@mui/icons-material'
import { AppBar, IconButton, Toolbar } from '@mui/material'
import React from 'react'

type HeaderProps = {
  isMenuOpen: boolean
  toggleMenu: () => void
}

export function Header({ isMenuOpen, toggleMenu }: HeaderProps) {
  return (
    <AppBar position="relative" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1, height: '56px' }}>
      <Toolbar sx={{ justifyContent: 'flex-end', backgroundColor: '#ddd', height: '56px' }}>
        <IconButton
          edge="end"
          sx={{
            backgroundColor: '#aaa',
            color: '#fff',
            borderRadius: 2,
            '&:hover': {
              backgroundColor: '#bbb',
            },
          }}
          onClick={toggleMenu}
        >
          {isMenuOpen ? <Close /> : <Menu />}
        </IconButton>
      </Toolbar>
    </AppBar>
  )
}
