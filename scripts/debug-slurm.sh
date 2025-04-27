#!/bin/bash
NAMESPACE="slurm"
LOG_FILE="slurm-debug-$(date +'%Y%m%d%H%M%S').log"

echo "Starting debug at $(date)" | tee $LOG_FILE

echo -e "\n====== Kubernetes Version ======" | tee -a $LOG_FILE
kubectl version | tee -a $LOG_FILE

echo -e "\n====== Nodes ======" | tee -a $LOG_FILE
kubectl get nodes -o wide | tee -a $LOG_FILE

echo -e "\n====== Events in $NAMESPACE ======" | tee -a $LOG_FILE
kubectl get events -n $NAMESPACE --sort-by='.metadata.creationTimestamp' | tee -a $LOG_FILE

echo -e "\n====== Pods in $NAMESPACE ======" | tee -a $LOG_FILE
kubectl get pods -n $NAMESPACE -o wide | tee -a $LOG_FILE

echo -e "\n====== Pods Detailed Status ======" | tee -a $LOG_FILE
for pod in $(kubectl get pods -n $NAMESPACE -o name); do
  echo -e "\n---- Describe: $pod ----" | tee -a $LOG_FILE
  kubectl describe $pod -n $NAMESPACE | tee -a $LOG_FILE
  
  echo -e "\n---- Logs: $pod ----" | tee -a $LOG_FILE
  kubectl logs $pod -n $NAMESPACE --all-containers=true --tail=100 | tee -a $LOG_FILE
done

echo -e "\n====== StatefulSets & PVC Status ======" | tee -a $LOG_FILE
kubectl get statefulsets,pvc,pv -n $NAMESPACE -o wide | tee -a $LOG_FILE

echo -e "\nCompleted debug at $(date)" | tee -a $LOG_FILE
echo "Debug info stored in $LOG_FILE"
