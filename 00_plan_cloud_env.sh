#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==> Подготовка окружения...${NC}"

# Проверка наличия исходного ключа
if [ ! -f "./secrets/terraform_sa_key.json" ]; then
    echo -e "${RED}Ошибка: Файл terraform_sa_key.json не найден.${NC}"
    exit 1
fi

# Инициализация Terraform
echo -e "${GREEN}==> Инициализация Terraform...${NC}"
cd tf
terraform init -plugin-dir=../.terraform/providers
cd ..

# Запуск Plan
echo -e "${GREEN}==> Запуск Terraform Plan...${NC}"
cd tf
terraform plan
cd ..
