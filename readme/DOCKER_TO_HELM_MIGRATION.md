# Migration Guide: Docker Compose to Helm Charts

This guide helps you migrate from Docker Compose deployments to Kubernetes/Helm for the Agri-Help application.

## Table of Contents

1. [Overview](#overview)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Kubernetes Cluster Setup](#kubernetes-cluster-setup)
4. [Configuration Migration](#configuration-migration)
5. [Data Migration](#data-migration)
6. [Deployment](#deployment)
7. [Validation](#validation)
8. [Rollback Plan](#rollback-plan)

## Overview

### Comparison: Docker Compose vs Kubernetes/Helm

| Aspect | Docker Compose | Kubernetes/Helm |
|--------|----------------|-----------------|
| **Scope** | Single host | Cluster-wide |
| **Scaling** | Vertical only | Horizontal + Vertical |
| **HA** | None | Full HA support |
| **Upgrades** | Manual | Rolling updates |
| **Monitoring** | Basic | Enterprise-grade |
| **Networking** | Container networks | Service mesh ready |
| **Storage** | Local volumes | Persistent volumes |

## Pre-Migration Checklist

### Application Readiness
- [ ] All microservices are containerized
- [ ] Environment variables are documented
- [ ] Database schemas are up-to-date
- [ ] External dependencies are accessible from K8s cluster
- [ ] Health check endpoints are implemented
- [ ] Load testing has been completed

### Infrastructure Readiness
- [ ] Kubernetes cluster is provisioned
- [ ] Storage classes are configured
- [ ] Network policies are planned
- [ ] DNS is configured for services
- [ ] SSL/TLS certificates are obtained
- [ ] Firewall rules are configured

### Backup and Recovery
- [ ] Database backups are current
- [ ] Configuration backups are stored
- [ ] Rollback procedure is documented
- [ ] Team is trained on K8s basics

## Kubernetes Cluster Setup

### 1. Create Kubernetes Cluster

```bash
# Using Kind for development
kind create cluster --name agri-help-migration --image kindest/node:v1.28.0

# Using Minikube
minikube start --cpus=4 --memory=8192 --disk-size=50gb

# Using cloud providers (EKS, GKE, AKS) - follow cloud-specific documentation
```

### 2. Verify Cluster

```bash
kubectl cluster-info
kubectl get nodes
kubectl get all -n kube-system
```

### 3. Install Required Components

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install NGINX Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Install Cert-Manager (for TLS)
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Install Prometheus Stack (for monitoring)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

## Configuration Migration

### 1. Docker Compose to Helm Values Mapping

#### Docker Compose Environment
```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    image: agri-help-backend:latest
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://user:pass@db:5432/agri_chatbot
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY}
      REDIS_URL: redis://cache:6379
    depends_on:
      - db
      - cache
    volumes:
      - ./backend:/app
    command: uvicorn main:app --reload

  frontend:
    image: agri-help-frontend:latest
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    depends_on:
      - backend

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: agri_user
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: agri_chatbot
    volumes:
      - postgres_data:/var/lib/postgresql/data

  cache:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

#### Helm Values Equivalent
```yaml
# values.yaml
backend:
  enabled: true
  image:
    repository: agri-help-backend
    tag: latest
  env:
    DATABASE_URL: postgresql://agri_user:changeme@postgresql:5432/agri_chatbot
    OPENROUTER_API_KEY: ${OPENROUTER_API_KEY}
    REDIS_URL: redis://redis-master:6379
  service:
    port: 8000
  resources:
    requests:
      cpu: 500m
      memory: 512Mi

frontend:
  enabled: true
  image:
    repository: agri-help-frontend
    tag: latest
  env:
    NEXT_PUBLIC_API_URL: http://backend:8000

postgresql:
  enabled: true
  auth:
    username: agri_user
    password: changeme
    database: agri_chatbot
  persistence:
    size: 10Gi

redis:
  enabled: true
  persistence:
    size: 5Gi
```

### 2. Create Secrets

```bash
# Create secret for API keys
kubectl create secret generic app-secrets \
  --from-literal=openrouter_api_key='your-api-key' \
  --from-literal=aws_access_key='your-access-key' \
  -n agri-help

# Create Docker registry secret
kubectl create secret docker-registry docker-secret \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  -n agri-help

# Using Sealed Secrets (recommended)
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
```

### 3. Create ConfigMaps

```bash
# Create ConfigMap for application configuration
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=info \
  --from-literal=ENVIRONMENT=production \
  -n agri-help
```

## Data Migration

### 1. Database Migration

```bash
# 1. Create backup from Docker Compose
docker-compose exec db pg_dump -U agri_user agri_chatbot > backup.sql

# 2. Create PostgreSQL pod in K8s
helm install postgresql ./helm/agri-help-app \
  -n agri-help \
  -f values.yaml

# 3. Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod \
  -l app=postgresql \
  -n agri-help \
  --timeout=300s

# 4. Copy backup to pod
kubectl cp backup.sql agri-help/postgresql-0:/tmp/backup.sql

# 5. Restore database
kubectl exec -it agri-help/postgresql-0 -- \
  psql -U agri_user agri_chatbot < /tmp/backup.sql

# 6. Verify restoration
kubectl exec -it agri-help/postgresql-0 -- \
  psql -U agri_user agri_chatbot -c "SELECT COUNT(*) FROM information_schema.tables"
```

### 2. Volume Data Migration

```bash
# 1. Export Docker volumes
docker run --rm -v agri-help_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-data.tar.gz -C /data .

# 2. Create PVC in Kubernetes
kubectl apply -f - << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: agri-help
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
EOF

# 3. Import data into PVC
kubectl run -it --rm import-data \
  --image=alpine \
  -n agri-help \
  -- sh -c "
  apk add tar
  tar xzf /backup/postgres-data.tar.gz -C /data
  "
```

### 3. Redis Cache Migration

```bash
# 1. Export Redis data from Docker Compose
docker-compose exec cache redis-cli --rdb /tmp/dump.rdb
docker cp docker-compose_cache_1:/tmp/dump.rdb ./redis-dump.rdb

# 2. Copy to K8s Redis pod
kubectl cp redis-dump.rdb agri-help/redis-master-0:/data/

# 3. Restore in Redis
kubectl exec -it agri-help/redis-master-0 -- redis-cli MODULE LOAD /data/dump.rdb
```

## Deployment

### 1. Pre-Deployment Validation

```bash
# Validate Helm chart
helm lint ./helm/agri-help-app --strict

# Check template rendering
helm template agri-help ./helm/agri-help-app \
  --values values-prod.yaml > rendered.yaml

# Verify rendered manifests
kubectl apply -f rendered.yaml --dry-run=client

# Check image availability
docker pull agri-help-backend:latest
docker pull agri-help-frontend:latest
```

### 2. Canary Deployment

Start with a small subset of users:

```bash
# Deploy to development namespace
kubectl create namespace agri-help-dev
helm install agri-help ./helm/agri-help-app \
  -n agri-help-dev \
  -f values-dev.yaml

# Verify deployment
kubectl get all -n agri-help-dev
kubectl logs -n agri-help-dev -l app=backend -f

# Run smoke tests
./scripts/smoke-tests.sh

# If successful, proceed to staging
```

### 3. Staging Deployment

```bash
# Deploy to staging
kubectl create namespace agri-help-staging
helm install agri-help ./helm/agri-help-app \
  -n agri-help-staging \
  -f values-staging.yaml

# Run comprehensive tests
./scripts/integration-tests.sh

# Load testing
k6 run load-test.js

# User acceptance testing
# - Verify all features work
# - Check performance
# - Validate integrations
```

### 4. Production Deployment

```bash
# Deploy to production
kubectl create namespace agri-help-prod
helm install agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  -f values-prod.yaml

# Monitor rollout
kubectl rollout status deployment -n agri-help-prod

# Verify all services
kubectl get all -n agri-help-prod
```

## Validation

### 1. Service Connectivity

```bash
# Check all services
kubectl get svc -n agri-help-prod
kubectl get endpoints -n agri-help-prod

# Test service connectivity
kubectl exec -it agri-help-prod/backend-0 -- \
  curl http://postgresql:5432

# Test health endpoints
kubectl exec -it agri-help-prod/backend-0 -- \
  curl http://localhost:8000/health
```

### 2. Data Integrity

```bash
# Verify database data
kubectl exec -it agri-help-prod/postgresql-0 -- \
  psql -U agri_user agri_chatbot -c "SELECT COUNT(*) FROM your_table"

# Verify Redis data
kubectl exec -it agri-help-prod/redis-master-0 -- \
  redis-cli KEYS '*' | wc -l

# Verify application functionality
curl http://agri-help-prod/api/health
curl http://agri-help-prod/api/query -d '{"question": "Test"}'
```

### 3. Performance Validation

```bash
# Check resource usage
kubectl top pods -n agri-help-prod
kubectl top nodes

# Monitor metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access http://localhost:9090

# Check logs for errors
kubectl logs -n agri-help-prod -l app=backend --tail=100
```

### 4. Security Validation

```bash
# Verify RBAC
kubectl auth can-i get pods --as=system:serviceaccount:agri-help-prod:agri-help

# Check network policies
kubectl get networkpolicies -n agri-help-prod

# Verify pod security
kubectl get pods -n agri-help-prod -o yaml | grep -A 10 "securityContext"

# Scan images for vulnerabilities
trivy image agri-help-backend:latest
trivy image agri-help-frontend:latest
```

## Rollback Plan

### Scenario 1: Immediate Rollback

```bash
# If deployment fails immediately
helm rollback agri-help -n agri-help-prod

# Restart from Docker Compose
docker-compose up -d

# Verify services are restored
docker-compose ps
```

### Scenario 2: Data Rollback

```bash
# Restore from database backup
kubectl exec -it agri-help-prod/postgresql-0 -- \
  psql -U agri_user agri_chatbot < /backups/backup-pre-migration.sql

# Verify data
docker-compose exec db psql -U agri_user agri_chatbot -c "SELECT COUNT(*) FROM your_table"
```

### Scenario 3: Phased Rollback

```bash
# 1. Reduce K8s traffic
kubectl scale deployment backend -n agri-help-prod --replicas=0

# 2. Direct traffic back to Docker Compose
# Update load balancer/DNS configuration

# 3. Monitor for issues
kubectl get pods -n agri-help-prod

# 4. Full rollback if needed
helm uninstall agri-help -n agri-help-prod
docker-compose up -d
```

## Post-Migration

### 1. Clean Up Docker Resources

```bash
# Stop Docker Compose services (only after confirming K8s stability)
docker-compose down

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Backup Docker Compose configuration
tar czf docker-compose-backup.tar.gz docker-compose.yml .env
```

### 2. Update Documentation

- [ ] Update deployment runbooks
- [ ] Document K8s infrastructure
- [ ] Create troubleshooting guides
- [ ] Train team on K8s operations
- [ ] Update CI/CD pipelines

### 3. Monitor for Issues

```bash
# Set up monitoring alerts
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring-alerts.yaml

# Create on-call runbook
# - Pod restart procedures
# - Database recovery steps
# - Network troubleshooting
# - Performance tuning
```

### 4. Optimization

```bash
# Review resource usage
kubectl top pods -n agri-help-prod

# Optimize resource requests/limits
# Review and adjust based on actual usage

# Enable autoscaling
helm upgrade agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  --set autoscaling.enabled=true
```

## Timeline Example

| Phase | Duration | Tasks |
|-------|----------|-------|
| Preparation | 1-2 weeks | Setup, training, documentation |
| Development | 1 week | Deploy to dev, test, validate |
| Staging | 1 week | Deploy to staging, comprehensive testing |
| Production | 1 day | Final production deployment |
| Validation | 1 week | Monitor, validate, optimize |
| Cleanup | 1 week | Remove Docker Compose, final documentation |

## Troubleshooting Migration Issues

### Networking Issues

```bash
# Pod can't reach database
kubectl exec -it <pod> -- nc -zv postgresql 5432

# Service DNS not resolving
kubectl exec -it <pod> -- nslookup postgresql.agri-help-prod.svc.cluster.local

# Fix: Check service endpoints
kubectl get endpoints -n agri-help-prod
```

### Data Migration Issues

```bash
# Backup/restore failed
kubectl exec -it postgresql-0 -- pg_basebackup -D /backup

# Verify database integrity
kubectl exec -it postgresql-0 -- pg_upgrade --check
```

### Performance Issues

```bash
# Application slow after migration
kubectl top pods -n agri-help-prod
kubectl get hpa -n agri-help-prod -w

# Adjust resources
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.limits.cpu=4000m
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Docker Compose vs Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-docker-compose/)
- [Database Migration Best Practices](https://cloud.google.com/solutions/migrating-data-to-kubernetes)
