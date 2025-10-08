from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncio
from typing import Set

active: Set[WebSocket] = set()

#Serverstart mit:
# python -m uvicorn pyServer:app --reload --host 0.0.0.0 --port 8000

#Server schließt mit Strg+C
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startphase
    async def ticker():
        while True:
            await asyncio.sleep(5)
            for peer in list(active):
                try:
                    await peer.send_text("SERVER-TICK: 5s vergangen")
                except Exception:
                    active.discard(peer)
    task = asyncio.create_task(ticker())
    yield
    # Shutdownphase
    task.cancel()

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # für Tests offen
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"ok":True}

@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    print("WS handshake incoming")  # <-- MUSS beim Verbindungsversuch erscheinen
    await ws.accept()
    await ws.send_text("SERVER: Verbunden")
    try:
        while True:
            msg = await ws.receive_text()
            await ws.send_text(f"ECHO: {msg}")
    except WebSocketDisconnect:
        print("WS disconnected")