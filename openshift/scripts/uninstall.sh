#!/bin/bash

# Harness Chaos Engineering V2 - Uninstall Script
# This script removes all HCE V2 resources from OpenShift

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="${HCE_NAMESPACE:-hce}"

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Harness Chaos Engineering V2${NC}"
echo -e "${YELLOW}Uninstallation${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

# Check if running on OpenShift
if ! oc version &>/dev/null; then
    echo -e "${RED}Error: oc CLI not found. Please install OpenShift CLI.${NC}"
    exit 1
fi

echo -e "${RED}WARNING: This will remove all HCE V2 resources from namespace '${NAMESPACE}'${NC}"
echo -e "${RED}This includes SCCs, service accounts, roles, and bindings.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${GREEN}Starting uninstallation...${NC}"
echo ""

# Step 1: Remove SCC bindings
echo -e "${YELLOW}Step 1: Removing SCC bindings from service accounts...${NC}"
oc adm policy remove-scc-from-user hce-basic-pod-scc -z hce-pod-basic -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-pod-exec-scc -z hce-pod-exec -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-stress-scc -z hce-stress -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-network-scc -z hce-network -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-network-policy-scc -z hce-network-policy -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-node-drain-scc -z hce-node-admin -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-node-restart-scc -z hce-node-restart -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-basic-pod-scc -z hce-kubelet-density -n "${NAMESPACE}" 2>/dev/null || true
oc adm policy remove-scc-from-user hce-admin-scc -z hce-admin,argo-chaos -n "${NAMESPACE}" 2>/dev/null || true
echo -e "${GREEN}✓ SCC bindings removed${NC}"
echo ""

# Step 2: Remove ClusterRoleBindings
echo -e "${YELLOW}Step 2: Removing ClusterRoleBindings...${NC}"
oc delete clusterrolebinding -l app.kubernetes.io/name=hce 2>/dev/null || true
echo -e "${GREEN}✓ ClusterRoleBindings removed${NC}"
echo ""

# Step 3: Remove ClusterRoles
echo -e "${YELLOW}Step 3: Removing ClusterRoles...${NC}"
oc delete clusterrole -l app.kubernetes.io/name=hce 2>/dev/null || true
echo -e "${GREEN}✓ ClusterRoles removed${NC}"
echo ""

# Step 4: Remove namespace (includes service accounts, roles, rolebindings)
echo -e "${YELLOW}Step 4: Removing namespace '${NAMESPACE}'...${NC}"
oc delete namespace "${NAMESPACE}" 2>/dev/null || true
echo -e "${GREEN}✓ Namespace removed${NC}"
echo ""

# Step 5: Remove SCCs
echo -e "${YELLOW}Step 5: Removing Security Context Constraints...${NC}"
read -p "Do you want to remove the SCCs? They can be reused for other namespaces. (yes/no): " -r
echo ""
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    oc delete scc hce-basic-pod-scc 2>/dev/null || true
    oc delete scc hce-pod-exec-scc 2>/dev/null || true
    oc delete scc hce-stress-scc 2>/dev/null || true
    oc delete scc hce-network-scc 2>/dev/null || true
    oc delete scc hce-network-policy-scc 2>/dev/null || true
    oc delete scc hce-node-drain-scc 2>/dev/null || true
    oc delete scc hce-node-restart-scc 2>/dev/null || true
    oc delete scc hce-admin-scc 2>/dev/null || true
    echo -e "${GREEN}✓ SCCs removed${NC}"
else
    echo -e "${YELLOW}Skipping SCC removal${NC}"
fi
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Uninstallation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
