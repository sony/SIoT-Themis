export { default } from 'next-auth/middleware'
export const config = {
  matcher: [
    { source: '/((?!api|_next/static|_next/image|favicon.ico).*)', missing: [{ type: 'header', key: 'next-action' }] },
  ],
}
