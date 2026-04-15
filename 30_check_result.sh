#!/bin/bash
set -e

export KUBECONFIG=./secrets/config

kubectx mws-mk8s-mws-sdf-webinar

INGRESS_EXTERNAL_ADDR=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Внешний адрес ingress: ${INGRESS_EXTERNAL_ADDR}"

GITLAB_ROOT_PW=$(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)
echo "GitLab root password: ${GITLAB_ROOT_PW}"
