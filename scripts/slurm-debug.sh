#!/bin/bash

NAMESPACE="slurm"
LOG_FILE="slurm-debug-$(date '+%Y%m%d-%H%M%S').log"

{
  echo "===== Kubernetes Nodes ====="
  kubectl get nodes -o wide

  echo -e "\n===== Pod Status ====="
  kubectl get pods -n ${NAMESPACE}

  echo -e "\n===== Pod Descriptions (Not Running or Pending Pods) ====="
  PODS=$(kubectl get pods -n ${NAMESPACE} --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')
  for pod in ${PODS}; do
    echo -e "\n--- Describe Pod: ${pod} ---"
    kubectl describe pod ${pod} -n ${NAMESPACE}

    echo -e "\n--- Logs Pod: ${pod} ---"
    kubectl logs ${pod} -n ${NAMESPACE} --all-containers --tail=50
  done

  echo -e "\n===== Events in Namespace ${NAMESPACE} ====="
  kubectl get events -n ${NAMESPACE}

  echo -e "\n===== PVC and PV Status ====="
  kubectl get pvc,pv -n ${NAMESPACE}

  echo -e "\n===== Storage Classes ====="
  kubectl get storageclass

  echo -e "\n===== Helm Releases ====="
  helm ls -n ${NAMESPACE}

  echo -e "\n===== StatefulSet Status ====="
  kubectl get statefulsets -n ${NAMESPACE}
  
  echo -e "\n===== Job Status ====="
  kubectl get jobs -n ${NAMESPACE}

  JOBS=$(kubectl get jobs -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
  for job in ${JOBS}; do
    echo -e "\n--- Describe Job: ${job} ---"
    kubectl describe job ${job} -n ${NAMESPACE}
  done

} | tee "${LOG_FILE}"

echo -e "\nDebugging information captured in ${LOG_FILE}."
