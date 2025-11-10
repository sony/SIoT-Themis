export function isInvalidEndpoint(str: string): boolean {
  const bannedOrionChars = ['<', '>', '"', "'", '=', ';', '(', ')']
  return bannedOrionChars.some((char) => str.includes(char))
}
