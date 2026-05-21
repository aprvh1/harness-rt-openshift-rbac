# Architecture Overview

## Deployment Modes Comparison

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NAMESPACE MODE                               │
│                     (Pod-Level Faults Only)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Namespace: hce                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  Service Accounts (7):                                        │  │
│  │  ├─ hce-pod-basic                                            │  │
│  │  ├─ hce-pod-exec                                             │  │
│  │  ├─ hce-stress        (pod-level only)                      │  │
│  │  ├─ hce-network       (pod-level only)                      │  │
│  │  ├─ hce-network-policy                                       │  │
│  │  ├─ hce-admin                                                │  │
│  │  └─ argo-chaos                                               │  │
│  │                                                               │  │
│  │  RBAC: Roles (namespace-scoped)                             │  │
│  │  ├─ hce-pod-basic-role                                       │  │
│  │  ├─ hce-pod-exec-role                                        │  │
│  │  ├─ hce-stress-role                                          │  │
│  │  ├─ hce-network-role                                         │  │
│  │  ├─ hce-network-policy-role                                  │  │
│  │  └─ hce-admin-role                                           │  │
│  │                                                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ✓ Multi-tenant friendly                                            │
│  ✓ Isolated namespace permissions                                   │
│  ✗ NO node-level faults                                             │
└─────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                         CLUSTER MODE                                 │
│                (Pod-Level + Node-Level Faults)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Namespace: hce                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  Service Accounts (10):                                       │  │
│  │  ├─ hce-pod-basic                                            │  │
│  │  ├─ hce-pod-exec                                             │  │
│  │  ├─ hce-stress        (pod + node)                          │  │
│  │  ├─ hce-network       (pod + node)                          │  │
│  │  ├─ hce-network-policy                                       │  │
│  │  ├─ hce-node-admin    (node operations)                     │  │
│  │  ├─ hce-node-restart  (node restart)                        │  │
│  │  ├─ hce-kubelet-density (kubelet stress)                    │  │
│  │  ├─ hce-admin                                                │  │
│  │  └─ argo-chaos                                               │  │
│  │                                                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Cluster-Wide RBAC: ClusterRoles                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ├─ hce-pod-basic-clusterrole                                │  │
│  │  ├─ hce-pod-exec-clusterrole                                 │  │
│  │  ├─ hce-stress-clusterrole          [nodes: get, list]      │  │
│  │  ├─ hce-network-clusterrole         [nodes: get, list]      │  │
│  │  ├─ hce-network-policy-clusterrole                           │  │
│  │  ├─ hce-node-admin-clusterrole      [nodes: patch, update]  │  │
│  │  ├─ hce-node-restart-clusterrole    [secrets: get, list]    │  │
│  │  ├─ hce-kubelet-density-clusterrole [configmaps: get, list] │  │
│  │  └─ hce-admin-clusterrole                                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ✓ Full chaos coverage (pod + node)                                 │
│  ✓ Cluster-wide operations                                          │
│  ✓ Node-level fault support                                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## SCC Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     8 Security Context Constraints                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│  hce-basic-pod-scc  │  ← Minimal privileges
├─────────────────────┤
│ Privileged: false   │
│ Capabilities: []    │
│ Host Access: none   │
│ RunAsUser: NonRoot  │
└─────────────────────┘
         ↓
   hce-pod-basic
   └─ pod-delete
   └─ pod-failure
   └─ container-kill

┌─────────────────────┐
│  hce-pod-exec-scc   │  ← Low privileges + exec
├─────────────────────┤
│ Privileged: false   │
│ Capabilities: []    │
│ Host Access: none   │
│ Pods/exec: yes      │
└─────────────────────┘
         ↓
   hce-pod-exec
   └─ pod-cpu-hog-exec
   └─ pod-memory-hog-exec

┌─────────────────────┐
│   hce-stress-scc    │  ← Medium-high (SYS_ADMIN)
├─────────────────────┤
│ Privileged: true    │
│ Capabilities:       │
│   - SYS_ADMIN       │
│ Host PID: true      │
│ Host Path: true     │
└─────────────────────┘
         ↓
   hce-stress
   └─ pod-cpu-hog, pod-memory-hog, pod-io-stress
   └─ node-cpu-hog, node-memory-hog, node-io-stress (cluster mode)

┌─────────────────────┐
│   hce-network-scc   │  ← High (NET_ADMIN)
├─────────────────────┤
│ Privileged: true    │
│ Capabilities:       │
│   - NET_ADMIN       │
│ Host Network: true  │
│ Host PID: true      │
└─────────────────────┘
         ↓
   hce-network
   └─ pod-network-latency, pod-network-loss, pod-network-corruption
   └─ node-network-latency, node-network-loss (cluster mode)

┌─────────────────────────┐
│ hce-network-policy-scc  │  ← Low (NetworkPolicy CRUD)
├─────────────────────────┤
│ Privileged: false       │
│ Capabilities: []        │
│ Host Access: none       │
└─────────────────────────┘
         ↓
   hce-network-policy
   └─ pod-network-partition

┌─────────────────────┐
│ hce-node-drain-scc  │  ← Very high (node modification)
├─────────────────────┤
│ Privileged: true    │
│ Capabilities:       │
│   - SYS_ADMIN       │
│   - NET_ADMIN       │
│ Host Access: full   │
└─────────────────────┘
         ↓
   hce-node-admin
   └─ node-drain
   └─ node-taint
   └─ kubelet-service-kill

┌──────────────────────┐
│ hce-node-restart-scc │  ← Critical (node restart)
├──────────────────────┤
│ Privileged: true     │
│ Capabilities:        │
│   - SYS_ADMIN        │
│   - NET_ADMIN        │
│ Secrets: yes         │
└──────────────────────┘
         ↓
   hce-node-restart
   └─ node-restart

┌─────────────────────┐
│   hce-admin-scc     │  ← Administrative
├─────────────────────┤
│ Privileged: false   │
│ Escalation: true    │
│ Orchestration perms │
└─────────────────────┘
         ↓
   hce-admin, argo-chaos
   └─ Infrastructure orchestration
```

---

## Permission Flow

```
Chaos Experiment Pod
       ↓
   ServiceAccount
       ↓
    SCC Admission
       ↓
  SCC Assignment (based on binding)
       ↓
  SecurityContext Applied
       ↓
   RBAC Check (Role/ClusterRole)
       ↓
  Fault Execution
```

### Example: pod-delete Fault

```
1. Pod Spec
   ├─ serviceAccountName: hce-pod-basic
   └─ No special securityContext

2. SCC Admission Controller
   ├─ Check: hce-pod-basic has access to hce-basic-pod-scc
   └─ Assign: hce-basic-pod-scc

3. Applied SecurityContext
   ├─ allowPrivilegedContainer: false
   ├─ allowedCapabilities: []
   ├─ runAsUser: MustRunAsNonRoot
   └─ volumes: [configMap, secret, emptyDir, pvc]

4. RBAC Check
   ├─ Role: hce-pod-basic-role
   ├─ Resources: pods [create, delete, get, list, patch, update]
   └─ Result: ✓ Allowed

5. Fault Executes
   └─ Deletes target pod
```

### Example: node-drain Fault (Cluster Mode)

```
1. Pod Spec
   ├─ serviceAccountName: hce-node-admin
   └─ No special securityContext

2. SCC Admission Controller
   ├─ Check: hce-node-admin has access to hce-node-drain-scc
   └─ Assign: hce-node-drain-scc

3. Applied SecurityContext
   ├─ allowPrivilegedContainer: true
   ├─ allowedCapabilities: [SYS_ADMIN, NET_ADMIN]
   ├─ allowHostPID: true
   ├─ allowHostNetwork: true
   └─ runAsUser: RunAsAny

4. RBAC Check
   ├─ ClusterRole: hce-node-admin-clusterrole
   ├─ Resources:
   │  ├─ nodes [get, list, patch, update]
   │  ├─ pods/eviction [create, get, list]
   │  └─ pods [create, delete, get, list, patch, update]
   └─ Result: ✓ Allowed

5. Fault Executes
   └─ Drains target node
```

---

## Privilege Escalation Path

```
Increasing Privilege Level →

hce-basic-pod-scc
├─ No capabilities
├─ No host access
├─ MustRunAsNonRoot
└─ Use Case: Safe pod operations

hce-pod-exec-scc
├─ No capabilities
├─ No host access
├─ pods/exec access
└─ Use Case: Exec-based faults

hce-network-policy-scc
├─ No capabilities
├─ No host access
├─ NetworkPolicy CRUD
└─ Use Case: Network isolation

hce-stress-scc
├─ SYS_ADMIN capability
├─ Host PID access
├─ Privileged container
└─ Use Case: Cgroup manipulation

hce-network-scc
├─ NET_ADMIN capability
├─ Host Network access
├─ Privileged container
└─ Use Case: Network manipulation

hce-node-drain-scc
├─ SYS_ADMIN + NET_ADMIN
├─ Full host access
├─ Node modification
└─ Use Case: Node operations

hce-node-restart-scc
├─ SYS_ADMIN + NET_ADMIN
├─ Full host access
├─ Secrets access
└─ Use Case: Node restart (highest)
```

---

## File Organization Logic

### Why Separate Files?

**Namespace Mode**:
```
03-roles-pod-basic.yaml       ← Clear: Pod basic operations
04-roles-pod-exec.yaml        ← Clear: Pod exec operations
05-roles-stress.yaml          ← Clear: Pod stress (no node access)
06-roles-network.yaml         ← Clear: Pod network (no node access)
07-roles-network-policy.yaml  ← Clear: NetworkPolicy operations
08-roles-admin.yaml           ← Clear: Admin operations
09-rolebindings.yaml          ← Binds all above roles
```

**Cluster Mode**:
```
03-clusterroles-pod-basic.yaml      ← Clear: Pod basic (cluster-wide)
04-clusterroles-pod-exec.yaml       ← Clear: Pod exec (cluster-wide)
05-clusterroles-stress.yaml         ← Clear: Pod + Node stress
06-clusterroles-network.yaml        ← Clear: Pod + Node network
07-clusterroles-network-policy.yaml ← Clear: NetworkPolicy (cluster-wide)
08-clusterroles-node-admin.yaml     ← Clear: Node admin operations
09-clusterroles-node-restart.yaml   ← Clear: Node restart
10-clusterroles-kubelet-density.yaml← Clear: Kubelet density
11-clusterroles-admin.yaml          ← Clear: Infrastructure admin
12-clusterrolebindings.yaml         ← Binds all above ClusterRoles
```

### Benefits

1. **Easy to Understand**: File name tells you exactly what's inside
2. **Easy to Modify**: Edit only the file you need
3. **Easy to Review**: Git diffs show exactly what changed
4. **Easy to Debug**: Find the right file immediately
5. **No Confusion**: Namespace mode has NO node-level files

---

## Decision Matrix

### When to Use Namespace Mode?

✅ Use when:
- Multi-tenant OpenShift cluster
- Security requirement: Isolate chaos to single namespace
- Only need pod-level faults
- Want minimal cluster-wide permissions

❌ Don't use when:
- Need node-level faults (node-drain, node-restart, etc.)
- Need cluster-wide chaos operations
- Single-tenant cluster where cluster mode is acceptable

### When to Use Cluster Mode?

✅ Use when:
- Need ALL chaos faults (pod + node)
- Want cluster-wide chaos coverage
- Dedicated/single-tenant cluster
- Testing disaster recovery scenarios requiring node operations

❌ Don't use when:
- Multi-tenant cluster with strict isolation requirements
- Only need pod-level faults
- Security policy prohibits cluster-wide permissions

---

## Comparison Table

| Aspect | Namespace Mode | Cluster Mode |
|--------|---------------|--------------|
| **RBAC Type** | Roles (namespace-scoped) | ClusterRoles (cluster-wide) |
| **Service Accounts** | 7 | 10 |
| **Pod-Level Faults** | ✅ Full support | ✅ Full support |
| **Node-Level Faults** | ❌ Not supported | ✅ Full support |
| **Files** | 9 YAML files | 12 YAML files |
| **Multi-Tenancy** | ✅ Excellent | ⚠️ Limited |
| **Security Isolation** | ✅ High | ⚠️ Moderate |
| **Complexity** | 🟢 Simple | 🟡 Moderate |
| **Recommended For** | Multi-tenant, pod-only | Single-tenant, full coverage |

---

This architecture ensures:
- ✅ Clear separation of concerns
- ✅ Principle of least privilege
- ✅ No confusion about namespace vs cluster mode
- ✅ Easy to understand and maintain
- ✅ Production-ready security posture
