#!/bin/bash

# Debug script for Slurm on Kubernetes

LOG_FILE="slurm-debug-$(date '+%Y%m%d%H%M%S').log"

exec &> >(tee -a "$LOG_FILE")

# Header
echo "====== Kubernetes Version ======"
kubectl version

echo "\n====== Kubernetes Nodes ======"
kubectl get nodes -o wide

echo "\n====== Slurm Namespace Resources ======"
kubectl get all -n slurm

# Pods Detail
echo "\n====== Pods Description ======"
for pod in $(kubectl get pods -n slurm --no-headers -o custom-columns=":metadata.name"); do
  echo "\n--- Description for Pod: $pod ---"
  kubectl describe pod "$pod" -n slurm
  
  echo "\n--- Logs for Pod: $pod ---"
  kubectl logs "$pod" -n slurm --all-containers=true --previous || kubectl logs "$pod" -n slurm --all-containers=true
  echo "\n=============================="
done

# PVCs & PVs
echo "\n====== PersistentVolumeClaims ======"
kubectl get pvc -n slurm
kubectl describe pvc -n slurm

echo "\n====== PersistentVolumes ======"
kubectl get pv
kubectl describe pv

# Storage Classes
echo "\n====== Storage Classes ======"
kubectl get storageclass

# Events
echo "\n====== Kubernetes Events in slurm Namespace ======"
kubectl get events -n slurm --sort-by=.metadata.creationTimestamp

# NodeSet Status
echo "\n====== NodeSet Status ======"
kubectl get nodeset -n slurm

for nodeset in $(kubectl get nodeset -n slurm --no-headers -o custom-columns=":metadata.name"); do
  echo "\n--- Description for NodeSet: $nodeset ---"
  kubectl describe nodeset "$nodeset" -n slurm
  echo "\n=============================="
done

# CSI Driver (EBS CSI)
echo "\n====== AWS EBS CSI Driver ======"
kubectl get pods -n kube-system | grep ebs-csi

# Tail output

cat << EOF

Logs are collected in: $LOG_FILE
Please upload this file for further troubleshooting.

EOF
