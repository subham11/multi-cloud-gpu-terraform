# Development Environment Deployment Guide

This guide provides step-by-step instructions for deploying the Agri-Help application in a development environment using Helm.

## Prerequisites

- Docker Desktop or Minikube installed
- Kubernetes cluster (local or remote)
- Helm 3.0+
- kubectl configured
- 4GB RAM and 20GB disk space available

## Quick Start

### 1. Set up Local Kubernetes Cluster

```bash
# Using Docker Desktop (macOS/Windows)
# Enable Kubernetes in Docker Desktop preferences

# Or using Minikube (all platforms)
minikube start --cpus=4 --memory=8192 --disk-size=50gb
eval $(minikube docker-env)  # Use Minikube's Docker daemon
```

### 2. Create Namespace

```bash
kubectl create namespace agri-help-dev
kubectl label namespace agri-help-dev environment=development monitoring=enabled
```

### 3. Install the Helm Chart

```bash
cd /path/to/multi-cloud-gpu-terraform

# Dry-run to preview changes
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-dev \
  --values ./helm/agri-help-app/values-dev.yaml \
  --dry-run --debug

# Install the chart
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-dev \
  --values ./helm/agri-help-app/values-dev.yaml

# Verify installation
helm status agri-help -n agri-help-dev
```

### 4. Monitor Deployment

```bash
# Watch pod deployment
kubectl get pods -n agri-help-dev -w

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod \
  -l app=backend \
  -n agri-help-dev \
  --timeout=300s
```

### 5. Access the Application

```bash
# Port-forward to backend
kubectl port-forward -n agri-help-dev svc/backend 8000:8000

# Port-forward to frontend
kubectl port-forward -n agri-help-dev svc/frontend 3000:3000

# Access the application
# Backend: http://localhost:8000
# Frontend: http://localhost:3000
# Backend API docs: http://localhost:8000/docs
```

## Development Workflow

### Hot Reloading with Skaffold

```bash
# Install Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-darwin-amd64
chmod +x skaffold
sudo mv skaffold /usr/local/bin

# Create skaffold.yaml in project root
cat > skaffold.yaml << EOF
apiVersion: skaffold/v3
kind: Config
metadata:
  name: agri-help
build:
  artifacts:
    - image: agri-help-backend
      docker:
        dockerfile: backend/Dockerfile
        context: backend/
    - image: agri-help-frontend
      docker:
        dockerfile: frontend/Dockerfile
        context: frontend/
deploy:
  helm:
    releases:
      - name: agri-help
        chartPath: ./helm/agri-help-app
        valuesFiles:
          - ./helm/agri-help-app/values-dev.yaml
        namespace: agri-help-dev
        imageStrategy:
          helm: {}
portForward:
  - resourceType: service
    resourceName: backend
    port: 8000
    localPort: 8000
  - resourceType: service
    resourceName: frontend
    port: 3000
    localPort: 3000
EOF

# Run Skaffold for continuous deployment
skaffold dev
```

### Local Database Development

```bash
# PostgreSQL
kubectl port-forward -n agri-help-dev svc/postgresql 5432:5432

# Connect from local machine
psql -h localhost -U agri_user -d agri_chatbot
# Password: changeme (from values-dev.yaml)

# Redis
kubectl port-forward -n agri-help-dev svc/redis-master 6379:6379
redis-cli -h localhost -p 6379

# Qdrant
kubectl port-forward -n agri-help-dev svc/qdrant 6333:6333
curl http://localhost:6333/health
```

### View Logs

```bash
# All logs from backend
kubectl logs -n agri-help-dev -l app=backend -f --all-containers=true

# All logs from frontend
kubectl logs -n agri-help-dev -l app=frontend -f --all-containers=true

# Logs from specific pod
kubectl logs -n agri-help-dev <pod-name> -f

# Previous logs (if pod crashed)
kubectl logs -n agri-help-dev <pod-name> --previous

# Logs from multiple pods
kubectl logs -n agri-help-dev -l app=backend,component=api -f
```

### Resource Monitoring

```bash
# CPU and memory usage
kubectl top pods -n agri-help-dev

# Watch resource usage
watch -n 2 'kubectl top pods -n agri-help-dev'

# Get resource requests/limits
kubectl get pods -n agri-help-dev -o json | \
  jq '.items[] | {name: .metadata.name, resources: .spec.containers[].resources}'

# Check node resources
kubectl describe nodes
```

### Environment Variables

```bash
# View current environment variables
kubectl exec -n agri-help-dev <pod-name> -- env

# Update ConfigMap
kubectl edit configmap backend-config -n agri-help-dev

# Update Secret (if using plain Kubernetes)
kubectl edit secret backend-secrets -n agri-help-dev
```

### Database Management

```bash
# PostgreSQL backup
kubectl exec -n agri-help-dev -c postgresql <pod-name> -- \
  pg_dump -U agri_user agri_chatbot > backup.sql

# PostgreSQL restore
kubectl exec -n agri-help-dev -c postgresql <pod-name> -- \
  psql -U agri_user agri_chatbot < backup.sql

# Reset database
kubectl exec -n agri-help-dev -c postgresql <pod-name> -- \
  dropdb -U agri_user agri_chatbot
kubectl exec -n agri-help-dev -c postgresql <pod-name> -- \
  createdb -U agri_user agri_chatbot
```

## Testing

### Running Tests in Cluster

```bash
# Deploy test pod
kubectl run test-runner --image=python:3.9 -n agri-help-dev -it --rm --restart=Never -- /bin/bash

# Inside pod: install dependencies and run tests
pip install -r requirements.txt
pytest tests/

# Run specific test file
pytest tests/test_backend.py -v
```

### API Testing with Postman/Curl

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test API documentation
curl http://localhost:8000/docs

# Test API with data
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What crops grow in my region?"}'
```

### Load Testing

```bash
# Install k6 for load testing
brew install k6

# Create load test script
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m30s', target: 50 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  let res = http.get('http://localhost:8000/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
EOF

# Run load test
k6 run load-test.js
```

## Troubleshooting

### Pod Crashes

```bash
# Check pod status
kubectl describe pod -n agri-help-dev <pod-name>

# View logs
kubectl logs -n agri-help-dev <pod-name> --previous

# Check events
kubectl get events -n agri-help-dev --sort-by='.lastTimestamp'

# Debug pod
kubectl run -it --rm debug --image=busybox --restart=Never -n agri-help-dev -- sh
```

### Network Issues

```bash
# Test connectivity between pods
kubectl exec -n agri-help-dev <pod1-name> -- ping <pod2-name>

# Check DNS resolution
kubectl exec -n agri-help-dev <pod-name> -- nslookup kubernetes.default

# Test service connectivity
kubectl exec -n agri-help-dev <pod-name> -- nc -zv backend 8000
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n agri-help-dev

# Check PV status
kubectl get pv

# Describe PVC for events
kubectl describe pvc -n agri-help-dev <pvc-name>
```

## Clean Up

```bash
# Delete the Helm release
helm uninstall agri-help -n agri-help-dev

# Delete the namespace
kubectl delete namespace agri-help-dev

# Delete local cluster (Minikube)
minikube delete
```

## Next Steps

1. Explore the application logs and metrics
2. Make code changes and rebuild containers
3. Test API endpoints
4. Set up debugging with IDE (VSCode, PyCharm)
5. Configure persistent storage for databases
6. Deploy to staging environment

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/)
