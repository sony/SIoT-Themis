'use server'
import cors from 'cors'
import { Server as SocketServer } from 'socket.io'

import type { NextApiResponseWebSocket } from '@/app/types/websocket'
import type { NextApiRequest } from 'next'

const corsMiddleware = cors()

if (process.env.NODE_ENV !== 'development') {
  console.log = console.info = console.debug = console.warn = console.error = () => {}
}

export default async function SocketHandler(req: NextApiRequest, res: NextApiResponseWebSocket) {
  console.log('req: ' + req)
  console.log(res.socket.server.io)
  const ip = req.headers['x-forwarded-for']
    ? req.headers['x-forwarded-for'].toString().replace('::ffff:', '')
    : req.socket.remoteAddress
  if (!ip || !['127.0.0.1', '::1'].includes(ip)) {
    return res.status(404).send('Not Found')
  }

  if (res.socket.server.io) {
    return res.send('already-set-up')
  }

  const io = new SocketServer(res.socket.server, {
    addTrailingSlash: false,
  })

  io.on('connection', (socket) => {
    const clientId = socket.id
    console.log(`A client connected. ID: ${clientId}`)
    io.emit('clientId', clientId)

    socket.on('message', (data) => {
      io.emit('message', data)
      console.log('Received message:', data)
    })

    socket.on('disconnect', () => {
      console.log('A client disconnected.')
    })
  })

  corsMiddleware(req, res, () => {
    res.socket.server.io = io
    res.end()
  })
}
