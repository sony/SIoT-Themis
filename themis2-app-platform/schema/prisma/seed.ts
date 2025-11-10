import { PrismaClient as PostgresClient } from './client/postgres'

const postgresClient = new PostgresClient()

async function main() {
  console.log()
}

main()
  .then(async () => {
    await postgresClient.$disconnect()
  })
  .catch(async (e) => {
    console.error(e)
    await postgresClient.$disconnect()
    process.exit(1)
  })
