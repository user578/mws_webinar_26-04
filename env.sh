export KUBECONFIG=./secrets/config
export PROXY="http://127.0.0.1:3180"
export REGISTRY_PASSWORD=$(cat ./secrets/registry_password 2>/dev/null || echo "")
