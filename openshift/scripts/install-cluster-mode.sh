#!/bin/bash

# Harness Chaos Engineering V2 - Cluster Mode Installation Script
# This script installs HCE V2 with finer-grained SCCs in cluster mode
# CLUSTER MODE: Supports BOTH pod-level AND node-level faults

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="${HCE_NAMESPACE:-hce}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Harness Chaos Engineering V2${NC}"
echo -e "${GREEN}Cluster Mode Installation${NC}"
echo -e "${YELLOW}(Pod-level AND Node-level faults)${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if running on OpenShift
if ! oc version &>/dev/null; then
    echo -e "${RED}Error: oc CLI not found. Please install OpenShift CLI.${NC}"
    exit 1
fi

echo -e "${YELLOW}Target Namespace: ${NAMESPACE}${NC}"
echo -e "${YELLOW}Scope: Cluster-wide chaos operations${NC}"
echo ""

# Step 1: Apply SCCs (requires cluster-admin)
echo -e "${GREEN}Step 1: Applying Security Context Constraints...${NC}"
oc apply -f "${BASE_DIR}/scc/"
echo -e "${GREEN}✓ SCCs applied${NC}"
echo ""

# Step 2: Create namespace and service accounts
echo -e "${GREEN}Step 2: Creating namespace and service accounts...${NC}"
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/cluster-mode/01-namespace.yaml" | oc apply -f -
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/cluster-mode/02-serviceaccounts.yaml" | oc apply -f -
echo -e "${GREEN}✓ Namespace and service accounts created${NC}"
echo ""

# Step 3: Create ClusterRoles
echo -e "${GREEN}Step 3: Creating ClusterRoles...${NC}"
for file in "${BASE_DIR}"/cluster-mode/*-clusterroles-*.yaml; do
    if [ -f "$file" ]; then
        oc apply -f "$file"
    fi
done
echo -e "${GREEN}✓ ClusterRoles created${NC}"
echo ""

# Step 4: Create ClusterRoleBindings
echo -e "${GREEN}Step 4: Creating ClusterRoleBindings...${NC}"
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/cluster-mode/12-clusterrolebindings.yaml" | oc apply -f -
echo -e "${GREEN}✓ ClusterRoleBindings created${NC}"
echo ""

# Step 5: Bind SCCs to Service Accounts
echo -e "${GREEN}Step 5: Binding SCCs to service accounts...${NC}"
oc adm policy add-scc-to-user hce-basic-pod-scc -z hce-pod-basic --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-pod-exec-scc -z hce-pod-exec --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-stress-scc -z hce-stress --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-network-scc -z hce-network --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-network-policy-scc -z hce-network-policy --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-node-drain-scc -z hce-node-admin --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-node-restart-scc -z hce-node-restart --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-basic-pod-scc -z hce-kubelet-density --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-admin-scc -z hce-admin,argo-chaos --as system:admin -n "${NAMESPACE}"
echo -e "${GREEN}✓ SCCs bound to service accounts${NC}"
echo ""

# Step 6: Verification
echo -e "${GREEN}Step 6: Verifying installation...${NC}"
echo ""
echo "SCCs:"
oc get scc | grep hce
echo ""
echo "Service Accounts in ${NAMESPACE}:"
oc get sa -n "${NAMESPACE}" | grep hce
echo ""
echo "ClusterRoles:"
oc get clusterroles | grep hce
echo ""
echo "ClusterRoleBindings:"
oc get clusterrolebindings | grep hce
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}CLUSTER MODE SUPPORTS:${NC}"
echo "✓ All pod-level chaos faults"
echo "✓ All node-level chaos faults"
echo ""
echo -e "${YELLOW}Runtime Configuration for OpenShift:${NC}"
echo "Set these environment variables in chaos pod specs:"
echo "  CONTAINER_RUNTIME=crio"
echo "  SOCKET_PATH=/run/crio/crio.sock"
echo "  SET_HELPER_DATA=false"
echo ""
echo -e "${YELLOW}Service Account → Fault Mapping:${NC}"
echo ""
echo "POD-LEVEL FAULTS:"
echo "  hce-pod-basic      → pod-delete, pod-failure, container-kill"
echo "  hce-pod-exec       → pod-cpu-hog-exec, pod-memory-hog-exec"
echo "  hce-stress         → pod-cpu-hog, pod-memory-hog, pod-io-stress"
echo "  hce-network        → pod-network-latency, pod-network-loss, pod-network-corruption"
echo "  hce-network-policy → pod-network-partition"
echo ""
echo "NODE-LEVEL FAULTS:"
echo "  hce-stress           → node-cpu-hog, node-memory-hog, node-io-stress"
echo "  hce-network          → node-network-latency, node-network-loss"
echo "  hce-node-admin       → node-drain, node-taint, kubelet-service-kill"
echo "  hce-node-restart     → node-restart"
echo "  hce-kubelet-density  → kubelet-density"
echo ""
echo "INFRASTRUCTURE:"
echo "  hce-admin          → Chaos infrastructure orchestration"
echo ""
