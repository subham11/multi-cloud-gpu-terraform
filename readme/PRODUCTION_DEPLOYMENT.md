# Production Environment Deployment Guide

This guide provides comprehensive instructions for deploying the Agri-Help application in a production environment with high availability, security, and scalability.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Infrastructure Preparation](#infrastructure-preparation)
3. [Security Setup](#security-setup)
4. [Helm Deployment](#helm-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring and Alerting](#monitoring-and-alerting)
7. [Maintenance and Updates](#maintenance-and-updates)
8. [Disaster Recovery](#disaster-recovery)

## Pre-Deployment Checklist

### Application Readiness
- [ ] All code has been reviewed and tested
- [ ] Unit tests pass with >80% coverage
- [ ] Integration tests pass
- [ ] Security scanning completed (SAST, dependency scan)
- [ ] Performance testing completed
- [ ] Documentation is complete and up-to-date

### Infrastructure Readiness
- [ ] Kubernetes cluster is provisioned and healthy
- [ ] Nodes have sufficient CPU, memory, and storage
- [ ] GPU nodes are available and configured (if needed)
- [ ] Container registry is set up and accessible
- [ ] Load balancer is configured
- [ ] SSL/TLS certificates are obtained

### Configuration Readiness
- [ ] Database credentials are generated and stored
- [ ] API keys are configured
- [ ] Environment variables are set
- [ ] Secrets are stored in sealed-secrets or external-secrets
- [ ] Resource limits and requests are defined
- [ ] Autoscaling parameters are configured

### Observability Readiness
- [ ] Logging solution is deployed
- [ ] Monitoring solution (Prometheus/Grafana) is deployed
- [ ] Alerting rules are configured
- [ ] Tracing solution is deployed (optional)
- [ ] Dashboard templates are created

## Infrastructure Preparation

### Create Kubernetes Cluster

```bash
# Example: AWS EKS with Terraform
terraform apply -target=module.eks_cluster

# Example: GCP GKE
gcloud container clusters create agri-help-prod \
  --region us-central1 \
  --machine-type n2-standard-4 \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10 \
  --enable-ip-alias \
  --enable-stackdriver-kubernetes

# Example: Azure AKS with Terraform
terraform apply -target=module.aks_cluster
```

### Configure kubectl

```bash
# Configure kubeconfig
# AWS EKS
aws eks update-kubeconfig --name agri-help-prod --region us-east-1

# GCP GKE
gcloud container clusters get-credentials agri-help-prod --zone us-central1-a

# Azure AKS
az aks get-credentials --resource-group agri-help-prod --name agri-help-prod

# Verify cluster access
kubectl get nodes
kubectl get all -n kube-system
```

### Verify Cluster Health

```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check resource availability
kubectl top nodes
```

### Set up Storage Classes

```bash
# Create storage classes for different workloads
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs  # Update based on cloud provider
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  fstype: ext4
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fstype: ext4
EOF

# Verify storage classes
kubectl get storageclass
```

### Install Ingress Controller

```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.replicas=3 \
  --set controller.resources.requests.cpu=500m \
  --set controller.resources.requests.memory=512Mi

# Verify installation
kubectl get svc -n ingress-nginx
```

### Install Cert-Manager

```bash
# Install cert-manager for SSL/TLS
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --set global.leaderElection.namespace=cert-manager

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@agri-help.local
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Verify installation
kubectl get clusterissuer
```

### Install Prometheus Stack

```bash
# Install kube-prometheus-stack for monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values - << EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
grafana:
  adminPassword: $(openssl rand -base64 32)
  persistence:
    enabled: true
    size: 10Gi
EOF

# Verify installation
kubectl get pods -n monitoring
```

## Security Setup

### Create Namespace with RBAC

```bash
# Create namespace
kubectl create namespace agri-help-prod
kubectl label namespace agri-help-prod environment=production

# Create service account
kubectl create serviceaccount agri-help -n agri-help-prod

# Create ClusterRole
kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: agri-help-pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
EOF

# Create ClusterRoleBinding
kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: agri-help-pod-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: agri-help-pod-reader
subjects:
- kind: ServiceAccount
  name: agri-help
  namespace: agri-help-prod
EOF
```

### Create Image Pull Secrets

```bash
# Create Docker registry secret
kubectl create secret docker-registry docker-secret \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n agri-help-prod

# Link secret to service account
kubectl patch serviceaccount agri-help -n agri-help-prod \
  -p '{"imagePullSecrets": [{"name": "docker-secret"}]}'
```

### Set Up Sealed Secrets

```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Get the sealing key
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealing-key.yaml

# Create sealed secret
echo -n mypassword | kubectl create secret generic mysecret --dry-run=client --from-file=/dev/stdin -o yaml | \
  kubeseal --format yaml > mysealedsecret.yaml

# Apply sealed secret
kubectl apply -f mysealedsecret.yaml -n agri-help-prod
```

### Configure Network Policies

```bash
# Apply network policies from Helm chart
helm upgrade agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --set networkPolicy.enabled=true \
  --values ./helm/agri-help-app/values-prod.yaml
```

### Pod Security Policy

```bash
# Apply Pod Security Policy
kubectl apply -f - << EOF
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'MustRunAs'
    seLinuxOptions:
      level: 's0:c123,c456'
  readOnlyRootFilesystem: false
EOF
```

## Helm Deployment

### Verify Helm Chart

```bash
# Validate chart syntax
helm lint ./helm/agri-help-app

# Check for warnings and errors
helm lint ./helm/agri-help-app --strict

# Render templates to verify
helm template agri-help ./helm/agri-help-app \
  --values ./helm/agri-help-app/values-prod.yaml > rendered.yaml

# Check template output
cat rendered.yaml | head -100
```

### Deploy Using Helm

```bash
# Add Helm repository (if using external repo)
helm repo add dpg-charts https://charts.example.com/dpg
helm repo update

# Create values override file for production
cat > custom-prod-values.yaml << EOF
# Production-specific overrides
ingress:
  hosts:
    - host: api.agri-help.io
      paths:
        - path: /
          pathType: Prefix
    - host: agri-help.io
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: agri-help-prod-tls
      hosts:
        - api.agri-help.io
        - agri-help.io

# Database credentials from secrets
postgresql:
  global:
    postgresql:
      auth:
        existingSecret: postgres-secret
        secretKeys:
          adminPasswordKey: password
          userPasswordKey: password

# Resource allocations for production
backend:
  replicaCount: 3
  resources:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi

frontend:
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
EOF

# Deploy with multiple values files
helm upgrade --install agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --create-namespace \
  --values ./helm/agri-help-app/values.yaml \
  --values ./helm/agri-help-app/values-prod.yaml \
  --values custom-prod-values.yaml \
  --timeout 5m \
  --wait \
  --wait-for-jobs

# Verify deployment
helm status agri-help -n agri-help-prod
helm get values agri-help -n agri-help-prod
```

### Deploy with GitOps (ArgoCD)

```bash
# Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace

# Create ArgoCD Application
kubectl apply -f - << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: agri-help
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/youorg/agri-help
    targetRevision: main
    path: helm/agri-help-app
    helm:
      releaseName: agri-help
      valuesObject:
        # Production values
        backend:
          replicaCount: 3
  destination:
    server: https://kubernetes.default.svc
    namespace: agri-help-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Post-Deployment Verification

### Verify Deployment Status

```bash
# Check all resources
kubectl get all -n agri-help-prod

# Check Helm release
helm list -n agri-help-prod

# Check deployment rollout status
kubectl rollout status deployment -n agri-help-prod

# Check pod status
kubectl get pods -n agri-help-prod -o wide

# Check services
kubectl get svc -n agri-help-prod

# Check ingress
kubectl get ingress -n agri-help-prod
```

### Verify Application Connectivity

```bash
# Get ingress IP/domain
kubectl get ingress -n agri-help-prod

# Test API endpoints
curl -v https://api.agri-help.io/health
curl -v https://api.agri-help.io/docs
curl -v https://agri-help.io/

# Check SSL certificate
echo | openssl s_client -servername agri-help.io -connect api.agri-help.io:443 2>/dev/null | openssl x509 -noout -dates -issuer
```

### Verify Database Connectivity

```bash
# Check PostgreSQL pod
kubectl get pods -n agri-help-prod -l app=postgresql

# Test database connection from pod
kubectl exec -it -n agri-help-prod <backend-pod> -- \
  python -c "import psycopg2; conn = psycopg2.connect('dbname=agri_chatbot user=agri_user host=postgresql password=changeme'); print('Connected'); conn.close()"

# Check Redis connection
kubectl exec -it -n agri-help-prod <backend-pod> -- \
  python -c "import redis; r = redis.Redis(host='redis-master', port=6379); print(r.ping())"

# Check Qdrant connection
kubectl exec -it -n agri-help-prod <backend-pod> -- \
  python -c "import requests; print(requests.get('http://qdrant:6333/health').json())"
```

### Run Smoke Tests

```bash
# Deploy test pod
kubectl run test-runner \
  --image=python:3.9 \
  --rm -it \
  -n agri-help-prod \
  -- bash

# Inside pod: run tests
pip install requests pytest
python -m pytest tests/smoke_tests.py -v
```

## Monitoring and Alerting

### Access Prometheus

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Access at http://localhost:9090
# Query examples:
# - container_memory_usage_bytes{namespace="agri-help-prod"}
# - rate(http_requests_total{namespace="agri-help-prod"}[5m])
```

### Access Grafana

```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Get admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Access at http://localhost:3000
```

### Configure Alerting Rules

```bash
# Create PrometheusRule
kubectl apply -f - << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: agri-help-alerts
  namespace: agri-help-prod
spec:
  groups:
  - name: agri-help.rules
    interval: 30s
    rules:
    - alert: BackendPodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total{namespace="agri-help-prod",pod=~"backend-.*"}[5m]) > 0
      for: 5m
      annotations:
        summary: "Backend pod {{ \$labels.pod }} is crash looping"

    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{namespace="agri-help-prod"} > 7516192768  # 7GB
      for: 5m
      annotations:
        summary: "High memory usage in {{ \$labels.pod }}"

    - alert: DatabaseConnectionError
      expr: rate(pg_client_backend_errors_total{namespace="agri-help-prod"}[5m]) > 0
      for: 5m
      annotations:
        summary: "Database connection errors detected"
EOF
```

## Maintenance and Updates

### Upgrade Application

```bash
# Check for updates
helm repo update dpg-charts

# Dry-run the upgrade
helm upgrade agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --values ./helm/agri-help-app/values-prod.yaml \
  --dry-run --debug

# Perform the upgrade
helm upgrade agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --values ./helm/agri-help-app/values-prod.yaml \
  --wait

# Verify upgrade
helm status agri-help -n agri-help-prod
kubectl rollout status deployment -n agri-help-prod
```

### Database Backup and Restore

```bash
# Backup PostgreSQL
kubectl exec -n agri-help-prod -c postgresql <pg-pod> -- \
  pg_dump -U agri_user agri_chatbot | gzip > backup-$(date +%Y%m%d).sql.gz

# Backup to persistent storage
kubectl exec -n agri-help-prod -c postgresql <pg-pod> -- \
  pg_dump -U agri_user agri_chatbot > /var/lib/postgresql/data/backup.sql

# Restore PostgreSQL
gunzip < backup-20240101.sql.gz | \
  kubectl exec -i -n agri-help-prod -c postgresql <pg-pod> -- \
  psql -U agri_user agri_chatbot
```

### Rollback Release

```bash
# View release history
helm history agri-help -n agri-help-prod

# Rollback to previous version
helm rollback agri-help -n agri-help-prod

# Rollback to specific revision
helm rollback agri-help 5 -n agri-help-prod

# Verify rollback
helm status agri-help -n agri-help-prod
```

## Disaster Recovery

### Backup Strategy

```bash
# Create backup script
cat > backup-agri-help.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/backups/agri-help"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# PostgreSQL backup
kubectl exec -n agri-help-prod -c postgresql postgresql-0 -- \
  pg_dump -U agri_user agri_chatbot | \
  gzip > ${BACKUP_DIR}/postgres_${TIMESTAMP}.sql.gz

# Helm values backup
helm get values agri-help -n agri-help-prod > ${BACKUP_DIR}/helm_values_${TIMESTAMP}.yaml

# PVC backup (if applicable)
kubectl get pvc -n agri-help-prod -o yaml > ${BACKUP_DIR}/pvc_${TIMESTAMP}.yaml

# Etcd backup (cluster backup)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save ${BACKUP_DIR}/etcd_${TIMESTAMP}.db

echo "Backup completed at ${TIMESTAMP}"
EOF

chmod +x backup-agri-help.sh
```

### Disaster Recovery Procedures

```bash
# 1. Restore from Helm values
helm rollback agri-help -n agri-help-prod

# 2. Restore database
gunzip < backup.sql.gz | \
  kubectl exec -i -n agri-help-prod postgresql-0 -- \
  psql -U agri_user agri_chatbot

# 3. Verify cluster health
kubectl get nodes
kubectl get all -n agri-help-prod

# 4. Run smoke tests
kubectl run test-runner --image=python:3.9 --rm -it -n agri-help-prod -- bash
```

## References

- [Helm Production Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Disaster Recovery Planning](https://kubernetes.io/docs/tasks/administer-cluster/disaster-recovery/backup/)
