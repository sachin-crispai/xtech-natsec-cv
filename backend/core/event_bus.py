import asyncio
from collections import defaultdict
from typing import AsyncIterator


class EventBus:
    def __init__(self):
        self._queues: dict[str, list[asyncio.Queue]] = defaultdict(list)

    def publish(self, topic: str, payload: dict):
        for q in self._queues[topic]:
            q.put_nowait(payload)

    async def subscribe(self, topic: str) -> AsyncIterator[dict]:
        q: asyncio.Queue = asyncio.Queue()
        self._queues[topic].append(q)
        try:
            while True:
                yield await q.get()
        finally:
            self._queues[topic].remove(q)
