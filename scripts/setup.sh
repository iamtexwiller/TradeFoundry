#!/usr/bin/env bash
# setup.sh — Provisiona o ambiente local do TradeFoundry do zero.
# Pré-requisitos: minikube, kubectl, helm, terraform instalados (ver README).

set -euo pipefail

echo "==> Verificando pré-requisitos..."
for cmd in minikube kubectl helm terraform; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERRO: '$cmd' não encontrado. Instale antes de continuar."
    exit 1
  fi
done

echo "==> Iniciando cluster Minikube (driver docker)..."
minikube start --driver=docker --cpus=4 --memory=6144 --kubernetes-version=stable

echo "==> Habilitando addon de ingress..."
minikube addons enable ingress

echo "==> Configurando contexto kubectl..."
kubectl config use-context minikube

echo "==> Verificando se terraform.tfvars existe..."
if [ ! -f "environments/local/terraform.tfvars" ]; then
  echo "AVISO: environments/local/terraform.tfvars não encontrado."
  echo "Copie environments/local/terraform.tfvars.example e preencha com suas credenciais do Grafana Cloud."
  exit 1
fi

echo "==> Inicializando Terraform..."
terraform init

echo "==> Aplicando plano..."
terraform plan -var-file="environments/local/terraform.tfvars"

echo ""
echo "Revise o plano acima. Para aplicar, rode:"
echo "  terraform apply -var-file=environments/local/terraform.tfvars"
