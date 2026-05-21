# Quick Start Guide

## 🚀 5-Minute Installation

### Step 1: Choose Your Mode

**Option A: Namespace Mode** (Pod-level faults only)
```bash
cd openshift/scripts
chmod +x *.sh
./install-namespace-mode.sh
```

**Option B: Cluster Mode** (Pod + Node-level faults)
```bash
cd openshift/scripts
chmod +x *.sh
./install-cluster-mode.sh
```

### Step 2: Verify Installation

```bash
# Check SCCs
oc get scc | grep hce

# Check service accounts
oc get sa -n hce | grep hce

# Check bindings
oc describe scc hce-basic-pod-scc | grep Users
```

### Step 3: Run Your First Chaos Experiment

Create a test pod with the appropriate service account:

```yaml
# test-pod-delete.yaml
apiVersion: v1
kind: Pod
metadata:
  name: chaos-test
  namespace: hce
spec:
  serviceAccountName: hce-pod-basic  # Use appropriate SA
  containers:
  - name: chaos
    image: alpine:latest
    command: ["sleep", "3600"]
    env:
    - name: CONTAINER_RUNTIME
      value: "crio"
    - name: SOCKET_PATH
      value: "/run/crio/crio.sock"
    - name: SET_HELPER_DATA
      value: "false"
```

Apply it:
```bash
oc apply -f test-pod-delete.yaml
oc get pod chaos-test -n hce
oc describe pod chaos-test -n hce | grep scc
```

---

## 📋 Service Account Cheat Sheet

### Namespace Mode (Pod-Level)

| Fault Type | Service Account |
|------------|----------------|
| pod-delete, pod-failure, container-kill | `hce-pod-basic` |
| pod-cpu-hog-exec, pod-memory-hog-exec | `hce-pod-exec` |
| pod-cpu-hog, pod-memory-hog, pod-io-stress | `hce-stress` |
| pod-network-* | `hce-network` |
| pod-network-partition | `hce-network-policy` |

### Cluster Mode (Add These Node-Level)

| Fault Type | Service Account |
|------------|----------------|
| node-cpu-hog, node-memory-hog, node-io-stress | `hce-stress` |
| node-network-latency, node-network-loss | `hce-network` |
| node-drain, node-taint, kubelet-service-kill | `hce-node-admin` |
| node-restart | `hce-node-restart` |
| kubelet-density | `hce-kubelet-density` |

---

## 🔧 Common Commands

### Check SCC Assignment
```bash
oc get pod <pod-name> -n hce -o yaml | grep "openshift.io/scc"
```

### Test SCC Permissions
```bash
oc auth can-i use scc/hce-basic-pod-scc --as=system:serviceaccount:hce:hce-pod-basic
```

### View SCC Details
```bash
oc describe scc hce-basic-pod-scc
```

### List All HCE Resources
```bash
# SCCs
oc get scc | grep hce

# Service Accounts
oc get sa -n hce | grep hce

# Roles (namespace mode)
oc get roles -n hce | grep hce

# ClusterRoles (cluster mode)
oc get clusterroles | grep hce

# RoleBindings (namespace mode)
oc get rolebindings -n hce | grep hce

# ClusterRoleBindings (cluster mode)
oc get clusterrolebindings | grep hce
```

---

## 🐛 Quick Troubleshooting

### Error: "unable to validate against any security context constraint"

**Fix**: Check SCC binding
```bash
oc adm policy add-scc-to-user hce-basic-pod-scc -z hce-pod-basic -n hce
```

### Error: "nodes is forbidden"

**Fix**: You need cluster mode for node-level faults
```bash
./install-cluster-mode.sh
```

### Error: "cannot find socket"

**Fix**: Add OpenShift runtime configuration
```yaml
env:
- name: CONTAINER_RUNTIME
  value: "crio"
- name: SOCKET_PATH
  value: "/run/crio/crio.sock"
- name: SET_HELPER_DATA
  value: "false"
```

---

## 📚 Next Steps

1. **Read the full README**: [README.md](./README.md)
2. **Understand the architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
3. **Review implementation details**: [SUMMARY.md](./SUMMARY.md)
4. **Plan your chaos experiments**: Choose appropriate service accounts
5. **Test in non-production first**: Validate SCC assignments

---

## 🎯 Decision Tree

```
Do you need node-level faults?
├─ NO  → Use Namespace Mode
│        └─ Run: ./install-namespace-mode.sh
│
└─ YES → Use Cluster Mode
         └─ Run: ./install-cluster-mode.sh

Is this a multi-tenant cluster?
├─ YES → Prefer Namespace Mode (if pod-level only)
│        └─ Better security isolation
│
└─ NO  → Use Cluster Mode
         └─ Full chaos coverage
```

---

## ⚡ One-Liner Installations

**Namespace Mode**:
```bash
cd openshift/scripts && chmod +x *.sh && ./install-namespace-mode.sh
```

**Cluster Mode**:
```bash
cd openshift/scripts && chmod +x *.sh && ./install-cluster-mode.sh
```

**Custom Namespace**:
```bash
export HCE_NAMESPACE=my-chaos && cd openshift/scripts && chmod +x *.sh && ./install-cluster-mode.sh
```

**Uninstall**:
```bash
cd openshift/scripts && ./uninstall.sh
```

---

## 📊 What Gets Installed

### Namespace Mode
- ✅ 8 Security Context Constraints (SCCs)
- ✅ 7 Service Accounts
- ✅ 6 Roles (namespace-scoped)
- ✅ 7 RoleBindings
- ✅ Pod-level chaos support
- ❌ No node-level chaos

### Cluster Mode
- ✅ 8 Security Context Constraints (SCCs)
- ✅ 10 Service Accounts
- ✅ 9 ClusterRoles (cluster-wide)
- ✅ 10 ClusterRoleBindings
- ✅ Pod-level chaos support
- ✅ Node-level chaos support

---

## 💡 Pro Tips

1. **Start with Namespace Mode**: Test pod-level faults first
2. **Verify SCC Assignment**: Always check which SCC was assigned
3. **Use Appropriate SA**: Match fault type to service account
4. **Add Runtime Config**: Always set CONTAINER_RUNTIME for OpenShift
5. **Test in Non-Prod**: Validate before production deployment

---

## 🎉 You're Ready!

Installation complete. Start running chaos experiments with confidence!

For detailed documentation, see [README.md](./README.md)
