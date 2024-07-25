#!/bin/bash

set -e

#remove double quotes on the value obtained from jq parse
obtained_resilience_score=$(echo "$1" | tr -d '"')
echo "Obtained Resilience Score: ${obtained_resilience_score}"

if [ $obtained_resilience_score -lt ${EXPECTED_RESILIENCE_SCORE} ]; then
  kubectl rollout undo deployment/cartservice -n boutique
  echo "verify rollback completion.."
  kubectl rollout status deployment cartservice -n boutique
  exit 1
fi 
