import type { NextApiResponseWebSocket } from '@/app/types/websocket'
import type { NextApiRequest } from 'next'

export default function handler(req: NextApiRequest, res: NextApiResponseWebSocket) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const { socketId } = req.query
  if (typeof socketId !== 'string' || !socketId) {
    return res.status(400).json({ error: 'Invalid socketId' })
  }

  const ship = req.body
  if (!ship) {
    return res.status(400).json({ error: 'Invalid data' })
  }

  if (!res.socket?.server?.io) {
    return res.status(500).json({ error: 'Socket.io is not initialized' })
  }
  res.socket.server.io.to(socketId).emit('message', ship)

  res.status(204).end()
}
