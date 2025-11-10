export class EltresAgentClient {
  origin: string

  constructor(origin: string) {
    this.origin = origin
  }

  async refresh(): Promise<void> {
    const refreshEltresAgentReponse = await fetch(`${this.origin}/refresh`, {
      method: 'POST',
    })
    if (!refreshEltresAgentReponse.ok) throw new Error()
  }
}
