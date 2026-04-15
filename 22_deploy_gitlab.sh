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

echo -e "${GREEN}==> Установка GitLab (Helm)...${NC}"
# Добавление репозитория если не добавлен
helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --create-namespace \
  --version 9.10.1 \
  -f k8s_manifests/gitlab/values.yaml \
  --timeout 600s \
  --wait-for-jobs

echo -e "${GREEN}==> GitLab установлен!${NC}"
