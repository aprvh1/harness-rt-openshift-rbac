#!/bin/bash

sleep 10
kubectl apply -f https://gitlab.com/ksatchit/hce-gitlab-integration-demo/-/raw/main/k8s/cartservice.yaml

echo "waiting for deploy rollout to complete.."

kubectl rollout status deployment cartservice -n boutique
