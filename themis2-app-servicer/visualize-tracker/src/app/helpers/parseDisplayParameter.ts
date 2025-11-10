import { getParameter } from './getParameter'

export const parseDisplayParameter = (searchParams: URLSearchParams, extraction: boolean) => {
  const overlayCircleDefaultColor = process.env.NEXT_PUBLIC_OVERLAY_CIRCLE_DEFAULT_COLOR as string
  const overlayCircleDefaultOpacity = Number(process.env.NEXT_PUBLIC_OVERLAY_CIRCLE_DEFAULT_OPACITY)

  let opacity = Number(getParameter(searchParams, 'opacity', extraction))
  if (isNaN(opacity)) {
    opacity = overlayCircleDefaultOpacity
  }

  return {
    showDataSource: getParameter(searchParams, 'showDataSource', extraction) === 'true',
    dataSource: getParameter(searchParams, 'dataSource', extraction),
    color: getParameter(searchParams, 'color', extraction) ?? overlayCircleDefaultColor,
    opacity: Math.min(Math.max(opacity, 0), 1),
  }
}
