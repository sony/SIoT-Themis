export function updateSearchParams(
  newKeyAndValues: [key: string, value: string | boolean][],
  searchParams: URLSearchParams | undefined | null,
): URLSearchParams {
  const newParams = searchParams ? new URLSearchParams(searchParams) : new URLSearchParams()
  newKeyAndValues.forEach(([key, value]) => {
    if (value) {
      newParams.set(key, value.toString())
    } else {
      newParams.delete(key)
    }
  })
  return newParams
}
