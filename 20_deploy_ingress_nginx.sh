#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

export KUBECONFIG=./secrets/config

if [ ! -f "$KUBECONFIG" ]; then
    echo -e "${RED}Ошибка: $KUBECONFIG не найден.${NC}"
    exit 1
fi

kubectx mws-mk8s-mws-sdf-webinar

echo -e "${GREEN}==> Установка Nginx Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace=ingress-nginx \
  --create-namespace \
  --version 4.4.0 \
  --values=k8s_manifests/ingress-nginx/values.yaml

echo -e "${GREEN}==> Nginx Ingress установлен!${NC}"
