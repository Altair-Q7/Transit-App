from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.services.ws_manager import manager

router = APIRouter(tags=["websocket"])


@router.websocket("/ws/trip/{trip_id}")
async def trip_websocket(websocket: WebSocket, trip_id: int):
    """
    The 'WebSocket (Real-Time Live Updates)' link on the architecture
    slide. A passenger's Flutter app opens this while viewing a trip's
    live map; every /trips/ping from the crew app is broadcast here.
    """
    await manager.connect(trip_id, websocket)
    try:
        while True:
            # Passenger clients don't need to send anything; this just
            # keeps the connection open and detects disconnects.
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(trip_id, websocket)
