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

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls gitlab-tls-secret -n gitlab \
  --cert=./secrets/certs/live/webinar-26-04.nufl.ru/fullchain.pem \
  --key=./secrets/certs/live/webinar-26-04.nufl.ru/privkey.pem \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}==> Сертификаты установлены!${NC}"
