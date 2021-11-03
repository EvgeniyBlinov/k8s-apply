#!/usr/bin/env bash
SCRIPT_PATH="$(dirname $0)"
ABSOLUTE_PATH="$(readlink -m ${SCRIPT_PATH})"
ROOT_PATH=$(dirname $ABSOLUTE_PATH)
########################################################################
# Load all variables from .env and export them all for Ansible to read
set -o allexport
source "${ROOT_PATH}/.env"
set +o allexport
########################################################################

KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
KUBE_SERVICEACCOUNT="${KUBE_SERVICEACCOUNT:-${KUBE_NAMESPACE}-admin}"
KUBE_ROLE_NAME="${KUBE_ROLE_NAME:-admin}"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${KUBE_SERVICEACCOUNT}
  namespace: ${KUBE_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${KUBE_ROLE_NAME}-${KUBE_SERVICEACCOUNT}
  namespace: ${KUBE_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: ${KUBE_SERVICEACCOUNT}
    namespace: kube-system
EOF
