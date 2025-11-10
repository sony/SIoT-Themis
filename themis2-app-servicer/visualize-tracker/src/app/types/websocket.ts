import type { Server as HttpServer } from 'http'
import type { Socket } from 'net'
import type { NextApiResponse } from 'next'
import type { Server as SocketServer } from 'socket.io'

export type NextApiResponseWebSocket = NextApiResponse & {
  socket: Socket & {
    server: HttpServer & {
      io: SocketServer
    }
  }
}

export type Message = {
  id: string
  author: string
  text: string
}
