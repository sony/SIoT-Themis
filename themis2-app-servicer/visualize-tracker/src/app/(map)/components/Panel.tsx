'use client'

import React from 'react'

type PanelProps = {
  children?: React.ReactNode
  value: number
  index: number
}

export function Panel({ children, value, index }: PanelProps) {
  return (
    <div hidden={value !== index} id={`panel-${index}`}>
      {value === index && children}
    </div>
  )
}
