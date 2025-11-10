'use client'

import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function ClientErrorHandler() {
  const router = useRouter()

  useEffect(() => {
    window.onerror = () => {
      router.push('/error')
    }
    window.onunhandledrejection = () => {
      router.push('/error')
    }
    return () => {
      window.onerror = null
      window.onunhandledrejection = null
    }
  }, [router])
  return null
}
