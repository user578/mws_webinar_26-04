#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==> Шаг 1: Деплой инфраструктуры (Kubernetes)...${NC}"

# Проверка утилит
for cmd in terraform kubectl mws base64; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Ошибка: $cmd не установлен.${NC}"
    exit 1
  fi
done

# Проверка файлов ключа
if [ ! -f "./secrets/terraform_sa_key.json" ]; then
    echo -e "${RED}Ошибка: Файл terraform_sa_key.json не найден.${NC}"
    exit 1
fi

# Проверка валидности JSON с помощью jq
if ! jq empty ./secrets/terraform_sa_key.json 2>/dev/null; then
    echo -e "${RED}Ошибка: Файл terraform_sa_key.json содержит невалидный JSON.${NC}"
    exit 1
fi

echo -e "${GREEN}==> Инициализация Terraform...${NC}"
cd tf
terraform init -plugin-dir=../.terraform/providers
cd ..

echo -e "${GREEN}==> Создание инфраструктуры...${NC}"
cd tf
terraform apply
cd ..

# Получаем переменные
CLUSTER_NAME=$(cd tf && terraform output -raw cluster_name)

echo -e "${GREEN}==> Настройка доступа к кластеру ($CLUSTER_NAME)...${NC}"
# Ожидаем готовности кластера для получения конфига
sleep 10

# Авторизация mws cli
mws init --service-account-authorized-key ./secrets/terraform_sa_key.json --force

# Получение kubeconfig
mws mk8s get-kubeconfig "$CLUSTER_NAME" --public-endpoint --force --kubeconfig ./secrets/config

echo -e "${GREEN}==> Проверка подключения к кластеру...${NC}"
export KUBECONFIG=./secrets/config
kubectl get nodes

echo -e "${GREEN}==> Кластер готов!${NC}"
