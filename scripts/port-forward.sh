#!/usr/bin/env bash
# port-forward.sh — Substitui o fluxo de acesso via Azure Bastion + Jump VM.
#
# No ambiente Azure original, o acesso ao cluster privado exigia:
#   Operador -> Bastion -> Jump VM -> kubectl (via VNet Peering) -> AKS
#
# No ambiente local, não há fronteira de rede privada a proteger (o cluster
# roda na própria máquina do desenvolvedor), então o acesso é direto via
# minikube tunnel ou port-forward. Essa simplificação é intencional e está
# documentada no README como trade-off da migração para custo zero.

set -euo pipefail

ENV="${1:-dev}"

if [[ ! "$ENV" =~ ^(dev|cert|prod)$ ]]; then
  echo "Uso: ./port-forward.sh [dev|cert|prod]"
  exit 1
fi

NAMESPACE="tradefoundry-${ENV}"
LOCAL_PORT=$((8080 + RANDOM % 100))

echo "==> Abrindo port-forward para o ambiente '${ENV}' (namespace: ${NAMESPACE})..."
echo "==> Acesse em: http://localhost:${LOCAL_PORT}/healthz"
echo "==> Pressione Ctrl+C para encerrar."

kubectl port-forward -n "$NAMESPACE" "svc/tradefoundry-app-${ENV}" "${LOCAL_PORT}:80"
