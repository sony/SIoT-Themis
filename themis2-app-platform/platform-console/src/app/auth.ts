import { redirect } from 'next/navigation'
import { getServerSession } from 'next-auth/next'
import KeycloakProvider from 'next-auth/providers/keycloak'

export const authOptions = {
  providers: [
    KeycloakProvider({
      clientId: process.env.KEYCLOAK_CLIENT_ID!,
      clientSecret: process.env.KEYCLOAK_CLIENT_SECRET!,
      issuer: `${process.env.KEYCLOAK_ENDPOINT}/realms/${process.env.KEYCLOAK_REALM}`,
    }),
  ],
  session: {
    maxAge: 24 * 60 * 10,
  },
}

export async function checkAuth(): Promise<void> {
  const session = await getServerSession(authOptions)
  if (!session) {
    redirect('/api/auth/signin')
  }
}
