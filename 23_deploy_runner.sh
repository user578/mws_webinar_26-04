#!/bin/bash
set -e

# --- Configuration ---
export KUBECONFIG=./secrets/config
NAMESPACE_GITLAB="gitlab"               # where GitLab itself is installed
NAMESPACE_RUNNER="gitlab-runner"        # where the new runner will be installed
RELEASE_NAME="gitlab-runner"            # Helm release name for the runner
HELM_VERSION="0.87.0"
VALUES_FILE="k8s_manifests/gitlab-runner/values.yaml"
GITLAB_URL="https://gitlab.webinar-26-04.nufl.ru"

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

# --- Context (optional, remove if not using kubectx) ---
kubectx mws-mk8s-mws-sdf-webinar

# --- 1. Extract Runner Registration Token ---
echo -e "${GREEN}==> Extracting runner registration token from secret...${NC}"
RUNNER_TOKEN=$(kubectl get secret gitlab-gitlab-runner-secret -n "$NAMESPACE_GITLAB" \
    -o jsonpath='{.data.runner-registration-token}' | base64 -d)

if [ -z "$RUNNER_TOKEN" ]; then
    echo -e "${RED}Failed to extract runner registration token.${NC}"
    exit 1
fi
echo -e "${GREEN}Runner token extracted successfully.${NC}"

# --- 2. Extract Root Password for API Verification ---
echo -e "${GREEN}==> Extracting GitLab root password...${NC}"
ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n "$NAMESPACE_GITLAB" \
    -o jsonpath='{.data.password}' | base64 -d)

if [ -z "$ROOT_PASSWORD" ]; then
    echo -e "${RED}Failed to extract root password. Cannot verify registration via API.${NC}"
    exit 1
fi

# --- 3. Install / Upgrade GitLab Runner with the token ---
echo -e "${GREEN}==> Installing/upgrading GitLab Runner (Helm)...${NC}"
helm upgrade --install "$RELEASE_NAME" gitlab/gitlab-runner \
    --namespace "$NAMESPACE_RUNNER" \
    --create-namespace \
    --version "$HELM_VERSION" \
    -f "$VALUES_FILE" \
    --set runnerRegistrationToken="$RUNNER_TOKEN" \
    --set gitlabUrl="$GITLAB_URL"
#    --set hostAliases[0].ip="171.22.75.103" \
#    --set hostAliases[0].hostnames[0]="gitlab.webinar.local"

echo -e "${GREEN}==> Helm deployment triggered. Waiting for runner pod to be ready...${NC}"

# --- 4. Wait for the runner pod to start ---
kubectl wait --for=condition=ready pod \
    -l app=gitlab-runner \
    -n "$NAMESPACE_RUNNER" \
    --timeout=10s

kubectl apply -f k8s_manifests/gitlab-runner/permissions_to_deploy.yaml

echo -e "${GREEN}==> Runner installed!${NC}"
