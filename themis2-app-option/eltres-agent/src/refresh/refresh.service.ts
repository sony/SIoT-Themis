import { Injectable, Logger, OnModuleInit } from '@nestjs/common'
import { PrismaClient as PostgresClient } from 'schema/prisma/client/postgres'

import type { Servicer } from 'schema/prisma/client/postgres'

@Injectable()
export class RefreshService implements OnModuleInit {
  private prisma = new PostgresClient()
  private servicers: Servicer[] = []
  private servicerData: Record<string, number> = {}
  private logger = new Logger(RefreshService.name)

  async onModuleInit() {
    await this.handleLoadAndRefreshServicers()
  }

  async refreshServicers(): Promise<void> {
    this.servicers = await this.prisma.servicer.findMany({
      where: {
        analyze: true,
      },
      orderBy: {
        id: 'asc',
      },
    })
  }

  async loadServicerData(): Promise<void> {
    try {
      const result = await this.prisma.servicer.findMany({
        select: {
          id: true,
          principalIds: true,
        },
      })
      this.servicerData = {}
      result.forEach((row: { id: number; principalIds: string[] }) => {
        row.principalIds.forEach((principalId: string) => {
          this.servicerData[principalId] = row.id
        })
      })
    } catch (error) {
      this.logger.error('Failed to load servicer data: ' + error.message)
    }
  }

  async checkForUpdates(): Promise<void> {
    await this.handleLoadAndRefreshServicers()
    this.logger.log('Completed servicer update check')
  }

  private async handleLoadAndRefreshServicers(): Promise<void> {
    await this.refreshServicers()
    await this.loadServicerData()
  }

  getCachedServicers(): Servicer[] {
    return this.servicers
  }

  getServicerData(): Record<string, number> {
    return this.servicerData
  }
}
