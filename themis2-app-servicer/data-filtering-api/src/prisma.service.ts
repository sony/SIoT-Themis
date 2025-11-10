import { Injectable } from '@nestjs/common'
import { PrismaClient } from 'schema/prisma/client'

@Injectable()
export class PrismaService extends PrismaClient {}
