export const isValidUrl = (url: string): boolean => {
  if (!url.trim()) return true

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return false
  }

  try {
    const urlObj = new URL(url)
    return urlObj.hostname.length > 0
  } catch {
    return false
  }
}
