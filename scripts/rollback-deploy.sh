#!/bin/bash

set -e 

kubectl rollout undo deployment/cartservice -n boutique
echo "verify rollback completion.."
kubectl rollout status deployment cartservice -n boutique
