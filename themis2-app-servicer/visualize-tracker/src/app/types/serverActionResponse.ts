export type ServerActionResponse<T> =
  | {
      success: true
      data: T
    }
  | {
      success: false
      errors: Record<string, string>
    }
