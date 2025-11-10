'use client'

import { useEffect } from 'react'

export function PreventZoom({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    document.body.addEventListener(
      'gesturestart',
      function (e) {
        e.preventDefault()
      },
      { passive: false },
    )
    document.body.addEventListener(
      'gesturechange',
      function (e) {
        e.preventDefault()
      },
      { passive: false },
    )
    document.body.addEventListener(
      'gestureend',
      function (e) {
        e.preventDefault()
      },
      { passive: false },
    )
  }, [])

  return children
}
