export class KongClient {
  origin: string

  constructor(origin: string) {
    this.origin = origin
  }

  async createApiKey(servicerId: string): Promise<string> {
    const createServicerResponse = await fetch(`${this.origin}/consumers`, {
      method: 'POST',
      body: new URLSearchParams({ username: servicerId }),
    })
    if (!createServicerResponse.ok) throw new Error()

    try {
      const createApiKeyResponse = await fetch(`${this.origin}/consumers/${servicerId}/key-auth`, {
        method: 'POST',
      })
      if (!createApiKeyResponse.ok) throw new Error()

      const createApiKeyResult = await createApiKeyResponse.json()
      return createApiKeyResult.key as string
    } catch {
      await fetch(`${this.origin}/consumers/${servicerId}`, {
        method: 'DELETE',
      })
      throw new Error()
    }
  }

  async deleteServicer(servicerId: string): Promise<void> {
    // When you delete a Servicer, the API Key is also deleted.
    const deleteServicerResponse = await fetch(`${this.origin}/consumers/${servicerId}`, {
      method: 'DELETE',
    })
    if (!deleteServicerResponse.ok) throw new Error()
  }
}
