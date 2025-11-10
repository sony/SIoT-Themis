export function getParameter(searchParams: URLSearchParams, key: string, extraction: boolean): string | undefined {
  const value = searchParams.get(key)
  if (extraction) {
    searchParams.delete(key)
  }
  return value || undefined
}
