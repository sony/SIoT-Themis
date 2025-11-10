export class ParseCsvError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ParseCsvError'
  }
}
