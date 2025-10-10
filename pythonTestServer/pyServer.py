from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncio
from typing import Set

active: Set[WebSocket] = set()

# start server with:
# python -m uvicorn pyServer:app --reload --host 0.0.0.0 --port 8000

# close server with Ctrl+C

@asynccontextmanager
async def lifespan(app: FastAPI):
    async def ticker():
        while True:
            await asyncio.sleep(5)
    task = asyncio.create_task(ticker())
    yield
    task.cancel()

app = FastAPI(lifespan=lifespan)




@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    #New Connection
    print("New Connection")  
    await ws.accept()
    active.add(ws)
    await ws.send_text("connected")
    for peer in list(active):
        if peer != ws:
            try:
                await peer.send_text("New user connected")
            except Exception:
                active.discard(peer)

    #Process Messages
    try:
        while True:
            msg = await ws.receive_text()
            
            # Ping the server
            if msg == "ping":
                await ws.send_text("pong")

            # sends received messages to all other clients
            else:
                for peer in list(active):
                    if peer != ws:
                        try:
                            await peer.send_text(msg)
                        except Exception:
                            active.discard(peer)
                    # Debug Option
                    #else:
                        # await peer.send_text(f"Message sent")

    #Process Disconnection
    except WebSocketDisconnect:
        print("disconnected")
        active.discard(ws)
        for peer in list(active):
            try:
                await peer.send_text("User disconnected")
            except Exception:
                active.discard(peer)
                await peer.send_text("User disconnected")