"""
TradeFoundry API — simula cotações e ordens de mercado, com fallback
gracioso quando dados reais (alimentados pelo workflow n8n via Redis)
não estão disponíveis.

Endpoints:
  GET  /quotes              → lista de cotações de todos os tickers
  GET  /quotes/{ticker}     → cotação de um ticker específico
  POST /orders              → cria uma ordem simulada
  GET  /orders              → lista ordens já criadas (em memória)
  GET  /health              → health check (mesmo formato já usado no projeto)
  GET  /metrics             → métricas Prometheus nativas (via instrumentator)
"""

import json
import os
import random
import time
import uuid
from datetime import datetime, timezone
from typing import Literal

import redis
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, Field

ENVIRONMENT = os.getenv("ENVIRONMENT", "dev").upper()
REDIS_HOST = os.getenv("REDIS_HOST", "")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

# As 4 ações com acesso livre e ilimitado na brapi.dev (sem necessidade de
# token) — ver https://brapi.dev/faq. Preço-base usado só como ponto de
# partida para a simulação de fallback, quando não há dado real no Redis.
TICKERS_BASE_PRICE = {
    "PETR4": 37.85,
    "VALE3": 61.20,
    "ITUB4": 33.40,
    "MGLU3": 8.50,
}

app = FastAPI(
    title="TradeFoundry API",
    description=(
        "API de demonstração simulando cotações e ordens de mercado. "
        "Cotações reais (quando disponíveis) são alimentadas por um workflow "
        "n8n que consulta a brapi.dev; na ausência de dado real, a API "
        "gera um valor simulado, garantindo disponibilidade contínua."
    ),
    version="1.0.0",
)

# Métricas Prometheus nativas (requests, latência por rota, etc.) expostas
# automaticamente em /metrics — complementa as métricas de infraestrutura
# (CPU, memória, restarts) já coletadas pelo kube-prometheus-stack.
Instrumentator().instrument(app).expose(app)

# Conexão com Redis é opcional por design: se REDIS_HOST não estiver
# configurado, ou se o Redis estiver fora do ar, a API cai no modo
# totalmente simulado sem erro — o mesmo princípio de fallback gracioso
# usado para a fonte de cotações externa.
_redis_client: redis.Redis | None = None
if REDIS_HOST:
    try:
        _redis_client = redis.Redis(
            host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, socket_connect_timeout=2
        )
    except Exception:
        _redis_client = None

# Armazenamento de ordens em memória — reseta a cada restart do pod, por
# design (este projeto demonstra infraestrutura, não persistência de domínio).
_orders: list[dict] = []


def _simulated_quote(ticker: str) -> dict:
    """Gera uma cotação simulada com pequena variação aleatória sobre o preço-base."""
    base = TICKERS_BASE_PRICE[ticker]
    variation_pct = random.uniform(-1.5, 1.5)
    price = round(base * (1 + variation_pct / 100), 2)
    return {
        "ticker": ticker,
        "price": price,
        "change_percent": round(variation_pct, 2),
        "currency": "BRL",
        "source": "simulated",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def _get_quote(ticker: str) -> dict:
    """Busca a cotação no Redis (alimentada pelo n8n); cai para simulado se ausente."""
    if _redis_client is not None:
        try:
            cached = _redis_client.get(f"quote:{ticker}")
            if cached:
                data = json.loads(cached)
                data["source"] = "real"
                return data
        except Exception:
            pass  # Redis indisponível — segue para o fallback simulado, sem propagar erro
    return _simulated_quote(ticker)


class OrderRequest(BaseModel):
    ticker: str = Field(..., description="Ticker do ativo (ex: PETR4)")
    side: Literal["buy", "sell"] = Field(..., description="Lado da ordem")
    quantity: int = Field(..., gt=0, description="Quantidade de ações")


class OrderResponse(BaseModel):
    order_id: str
    ticker: str
    side: str
    quantity: int
    price: float
    total: float
    status: str
    created_at: str


@app.get("/health")
def health():
    return {"message": f"Ambiente {ENVIRONMENT} - Status: UP"}


@app.get("/quotes")
def list_quotes():
    return {"quotes": [_get_quote(ticker) for ticker in TICKERS_BASE_PRICE]}


@app.get("/quotes/{ticker}")
def get_quote(ticker: str):
    ticker = ticker.upper()
    if ticker not in TICKERS_BASE_PRICE:
        raise HTTPException(
            status_code=404,
            detail=f"Ticker '{ticker}' não suportado. Disponíveis: {list(TICKERS_BASE_PRICE)}",
        )
    return _get_quote(ticker)


@app.post("/orders", response_model=OrderResponse, status_code=201)
def create_order(order: OrderRequest):
    ticker = order.ticker.upper()
    if ticker not in TICKERS_BASE_PRICE:
        raise HTTPException(
            status_code=404,
            detail=f"Ticker '{ticker}' não suportado. Disponíveis: {list(TICKERS_BASE_PRICE)}",
        )

    quote = _get_quote(ticker)
    price = quote["price"]
    total = round(price * order.quantity, 2)

    record = {
        "order_id": str(uuid.uuid4()),
        "ticker": ticker,
        "side": order.side,
        "quantity": order.quantity,
        "price": price,
        "total": total,
        "status": "filled",  # simulação: toda ordem é executada imediatamente
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    _orders.append(record)
    return record


@app.get("/orders")
def list_orders():
    return {"orders": _orders, "count": len(_orders)}
