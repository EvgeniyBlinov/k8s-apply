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


kubectl -n "${KUBE_NAMESPACE}" apply -f "${ROOT_PATH}/templates/k8s/account/role-${KUBE_ROLE_NAME}.yml"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${KUBE_SERVICEACCOUNT}
  namespace: ${KUBE_NAMESPACE}
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${KUBE_ROLE_NAME}-${KUBE_SERVICEACCOUNT}
  namespace: ${KUBE_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ${KUBE_SERVICEACCOUNT}
  namespace: ${KUBE_NAMESPACE}
roleRef:
  kind: Role
  name: ${KUBE_ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF
