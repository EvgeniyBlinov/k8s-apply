#!/usr/bin/env bash

KUBECONFIG_DIR="${KUBECONFIG_DIR}"

KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"
KUBE_SERVICEACCOUNT="${KUBE_SERVICEACCOUNT:-${KUBE_NAMESPACE}-admin}"
NEW_CONTEXT="${KUBE_NAMESPACE}"
KUBECONFIG_FILE="${KUBE_SERVICEACCOUNT}"

#[ -n "${KUBECONFIG_DIR}" ] && ( echo "cd ${KUBECONFIG_DIR}" && cd "${KUBECONFIG_DIR}" )

CONTEXT=$(kubectl config current-context)

SECRET_NAME=$(kubectl get serviceaccount ${KUBE_SERVICEACCOUNT} \
  --context ${CONTEXT} \
  --namespace ${KUBE_NAMESPACE} \
  -o jsonpath='{.secrets[0].name}')
TOKEN_DATA=$(kubectl get secret ${SECRET_NAME} \
  --context ${CONTEXT} \
  --namespace ${KUBE_NAMESPACE} \
  -o jsonpath='{.data.token}')

TOKEN=$(echo ${TOKEN_DATA} | base64 -d)

# Create dedicated kubeconfig
# Create a full copy
kubectl config view --raw > ${KUBECONFIG_FILE}.full.tmp
# Switch working context to correct context
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp config use-context ${CONTEXT}
# Minify
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp \
  config view --flatten --minify > ${KUBECONFIG_FILE}.tmp
# Rename context
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  rename-context ${CONTEXT} ${NEW_CONTEXT}
# Create token user
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-credentials ${CONTEXT}-${KUBE_NAMESPACE}-token-user \
  --token ${TOKEN}
# Set context to use token user
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --user ${CONTEXT}-${KUBE_NAMESPACE}-token-user
# Set context to correct namespace
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --namespace ${KUBE_NAMESPACE}
# Flatten/minify kubeconfig
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  view --flatten --minify > ${KUBECONFIG_FILE}
# Remove tmp
rm ${KUBECONFIG_FILE}.full.tmp
rm ${KUBECONFIG_FILE}.tmp


[ -n "${KUBECONFIG_DIR}" ] && mv "${KUBECONFIG_FILE}" "${KUBECONFIG_DIR}/${KUBECONFIG_FILE}"
