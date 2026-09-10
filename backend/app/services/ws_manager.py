"""
Real-time layer: "WebSocket (Real-Time Live Updates)" arrow on the
architecture slide, connecting Layer 1 (Flutter/Next.js clients)
straight through to Layer 2 (FastAPI core).

Kept in-process for the MVP (single worker). When scaling beyond one
FastAPI worker, swap the in-memory dict for Redis pub/sub subscriptions
(see services/redis_client.py — the channel naming is already there).
"""
from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._trip_subscribers: dict[int, set[WebSocket]] = defaultdict(set)

    async def connect(self, trip_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self._trip_subscribers[trip_id].add(websocket)

    def disconnect(self, trip_id: int, websocket: WebSocket) -> None:
        self._trip_subscribers[trip_id].discard(websocket)
        if not self._trip_subscribers[trip_id]:
            self._trip_subscribers.pop(trip_id, None)

    async def broadcast(self, trip_id: int, payload: dict) -> None:
        dead: list[WebSocket] = []
        for ws in self._trip_subscribers.get(trip_id, set()):
            try:
                await ws.send_json(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(trip_id, ws)


manager = ConnectionManager()
