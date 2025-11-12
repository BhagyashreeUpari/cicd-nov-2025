#!/usr/bin/env bash
# Usage: ./kubectl-apply-helm.sh <image> <tag> <namespace>
IMAGE=${1:-"<DOCKERHUB_USER>/cicd-demo"}
TAG=${2:-"latest"}
NS=${3:-"cicd"}

kubectl create ns ${NS} --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cicd-demo ./helm-chart --namespace ${NS} \
  --set image.repository=${IMAGE} --set image.tag=${TAG}

