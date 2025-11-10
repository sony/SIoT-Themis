export function isInvalidType(str: string): boolean {
  return /[^a-zA-Z0-9]/.test(str)
}
