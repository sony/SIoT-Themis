export type ServerActionResponse =
  | {
      success: true
    }
  | {
      success: false
      errors: Record<string, string>
    }
