'use client'
import { useState, Suspense } from 'react'

import { Header } from '@/app/(map)/components/Header'
import { Loading } from '@/app/(map)/components/Loading'
import { Menu } from '@/app/(map)/components/Menu'

export default function MapLayout({ children }: { children: React.ReactNode }) {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <>
      <Header isMenuOpen={isMenuOpen} toggleMenu={() => setIsMenuOpen(!isMenuOpen)} />
      <Suspense fallback={<Loading />}>
        <Menu isMenuOpen={isMenuOpen} onClose={() => setIsMenuOpen(false)} />
      </Suspense>
      {children}
    </>
  )
}
