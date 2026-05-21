#!/bin/bash

# Harness Chaos Engineering V2 - Namespace Mode Installation Script
# This script installs HCE V2 with finer-grained SCCs in namespace mode
# NAMESPACE MODE: Only supports POD-LEVEL faults within a namespace

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
echo -e "${GREEN}Namespace Mode Installation${NC}"
echo -e "${YELLOW}(POD-LEVEL faults only)${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if running on OpenShift
if ! oc version &>/dev/null; then
    echo -e "${RED}Error: oc CLI not found. Please install OpenShift CLI.${NC}"
    exit 1
fi

echo -e "${YELLOW}Target Namespace: ${NAMESPACE}${NC}"
echo -e "${YELLOW}Scope: Pod-level chaos faults only${NC}"
echo -e "${YELLOW}For node-level faults, use cluster mode installation.${NC}"
echo ""

# Step 1: Apply SCCs (requires cluster-admin)
echo -e "${GREEN}Step 1: Applying Security Context Constraints...${NC}"
oc apply -f "${BASE_DIR}/scc/"
echo -e "${GREEN}✓ SCCs applied${NC}"
echo ""

# Step 2: Create namespace and service accounts
echo -e "${GREEN}Step 2: Creating namespace and service accounts...${NC}"
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/namespace-mode/01-namespace.yaml" | oc apply -f -
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/namespace-mode/02-serviceaccounts.yaml" | oc apply -f -
echo -e "${GREEN}✓ Namespace and service accounts created${NC}"
echo ""

# Step 3: Create Roles
echo -e "${GREEN}Step 3: Creating Roles (namespace-scoped)...${NC}"
for file in "${BASE_DIR}"/namespace-mode/0*-roles-*.yaml; do
    if [ -f "$file" ]; then
        sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "$file" | oc apply -f -
    fi
done
echo -e "${GREEN}✓ Roles created${NC}"
echo ""

# Step 4: Create RoleBindings
echo -e "${GREEN}Step 4: Creating RoleBindings...${NC}"
sed "s/namespace: hce/namespace: ${NAMESPACE}/g" "${BASE_DIR}/namespace-mode/09-rolebindings.yaml" | oc apply -f -
echo -e "${GREEN}✓ RoleBindings created${NC}"
echo ""

# Step 5: Bind SCCs to Service Accounts (pod-level only)
echo -e "${GREEN}Step 5: Binding SCCs to service accounts...${NC}"
oc adm policy add-scc-to-user hce-basic-pod-scc -z hce-pod-basic --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-pod-exec-scc -z hce-pod-exec --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-stress-scc -z hce-stress --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-network-scc -z hce-network --as system:admin -n "${NAMESPACE}"
oc adm policy add-scc-to-user hce-network-policy-scc -z hce-network-policy --as system:admin -n "${NAMESPACE}"
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
echo "Roles in ${NAMESPACE}:"
oc get roles -n "${NAMESPACE}" | grep hce
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}NAMESPACE MODE SUPPORTS:${NC}"
echo "✓ Pod-level chaos faults only"
echo "✗ Node-level faults NOT supported (requires cluster mode)"
echo ""
echo -e "${YELLOW}Runtime Configuration for OpenShift:${NC}"
echo "Set these environment variables in chaos pod specs:"
echo "  CONTAINER_RUNTIME=crio"
echo "  SOCKET_PATH=/run/crio/crio.sock"
echo "  SET_HELPER_DATA=false"
echo ""
echo -e "${YELLOW}Service Account → Fault Mapping:${NC}"
echo "  hce-pod-basic      → pod-delete, pod-failure, container-kill"
echo "  hce-pod-exec       → pod-cpu-hog-exec, pod-memory-hog-exec"
echo "  hce-stress         → pod-cpu-hog, pod-memory-hog, pod-io-stress"
echo "  hce-network        → pod-network-latency, pod-network-loss, pod-network-corruption"
echo "  hce-network-policy → pod-network-partition"
echo "  hce-admin          → Infrastructure orchestration"
echo ""
echo -e "${RED}For node-level faults (node-drain, node-restart, etc.), use:${NC}"
echo "  ./install-cluster-mode.sh"
echo ""
