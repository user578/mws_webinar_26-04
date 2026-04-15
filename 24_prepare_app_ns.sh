#!/bin/bash
set -e

# --- Configuration ---
export KUBECONFIG=./secrets/config
NAMESPACE="app"               # where GitLab itself is installed
NAMESPACE_RUNNER="gitlab-runner"        # where the new runner will be installed
REGISTRY="registry.mwsapis.ru"
REGISTRY_USER="apikey"
PULL_SECRET_NAME="registry-pull-secret"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Checks ---
if [ ! -f "$KUBECONFIG" ]; then
    echo -e "${RED}Error: $KUBECONFIG not found${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: 'jq' is required but not installed.${NC}"
    exit 1
fi

kubectx mws-mk8s-mws-sdf-webinar

# Проверяем, задана ли REGISTRY_PASSWORD
if [ -z "$REGISTRY_PASSWORD" ]; then
    echo -e "${RED}REGISTRY_PASSWORD is not set. Cannot create image pull secret.${NC}"
    exit 1
fi

# Создаём или обновляем secret docker-registry
kubectl create secret docker-registry "${PULL_SECRET_NAME}" \
    --namespace="$NAMESPACE" \
    --docker-server="$REGISTRY" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}==> Secret 'PULL_SECRET_NAME' created/updated in namespace '$NAMESPACE'${NC}"

# Привязываем секрет к ServiceAccount 'default' в том же namespace
kubectl patch serviceaccount default -n "$NAMESPACE" -p "{\"imagePullSecrets\": [{\"name\": \"$PULL_SECRET_NAME\"}]}"

echo -e "${GREEN}==> ServiceAccount 'default' now uses secret '$PULL_SECRET_NAME' for pulling images${NC}"

kubectl apply -f ./app/prepare_k8s_ns/runner_permission_to_deploy.yaml
echo -e "${GREEN}==> Grant deploy permissions to gitlab-runner!${NC}"

# install cert
kubectl create secret tls app-tls-secret -n app \
  --cert=./secrets/certs/live/webinar-26-04.nufl.ru/fullchain.pem \
  --key=./secrets/certs/live/webinar-26-04.nufl.ru/privkey.pem \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}==> Cert installed!${NC}"

echo -e "${GREEN}==> Namespace app is prepared!${NC}"
