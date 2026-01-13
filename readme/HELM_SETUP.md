# Helm Charts for Multi-Cloud GPU Terraform

This directory contains Helm charts for deploying DPG (Digital Public Goods) applications with GPU support across multiple cloud providers.

## Table of Contents

1. [Overview](#overview)
2. [Chart Structure](#chart-structure)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Deployment](#deployment)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

## Overview

The Helm charts provide a standardized approach to deploy:
- **Backend Services** (FastAPI RAG Engine with GPU support)
- **Frontend Applications** (Next.js)
- **Databases** (PostgreSQL, Redis, Qdrant Vector DB)
- **Supporting Services** (Transcribe service, OAN UI)

## Chart Structure

```
helm/
├── agri-help-app/                 # Main application Helm chart
│   ├── Chart.yaml                 # Chart metadata
│   ├── values.yaml                # Default values (production)
│   ├── values-dev.yaml            # Development environment values
│   ├── values-staging.yaml        # Staging environment values
│   ├── values-prod.yaml           # Production-specific overrides
│   └── templates/                 # Kubernetes manifest templates
│       ├── _helpers.tpl           # Template helpers
│       ├── NOTES.txt              # Post-installation notes
│       ├── deployment.yaml        # Deployment manifests
│       ├── service.yaml           # Service manifests
│       ├── ingress.yaml           # Ingress manifests
│       ├── configmap.yaml         # Configuration data
│       ├── secret.yaml            # Sensitive data
│       ├── rbac.yaml              # RBAC resources
│       ├── network-policy.yaml    # Network policies
│       └── hpa.yaml               # Horizontal Pod Autoscaler
```

## Prerequisites

### Required Tools
- Helm 3.0+
- Kubernetes cluster 1.20+
- kubectl configured to access your cluster
- (Optional) Helm plugins:
  - `helm-diff` - Compare chart changes
  - `helm-secrets` - Manage secrets
  - `helm-values` - Manage multiple values files

### Install Prerequisites

```bash
# Install Helm (macOS)
brew install helm

# Install Helm plugins
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/jkroepke/helm-secrets

# Verify installation
helm version
helm plugin list
```

### Cluster Requirements

- **Minimum CPU**: 2 cores
- **Minimum Memory**: 4GB
- **Storage**: 20GB
- **GPU** (optional): NVIDIA GPU for GPU workloads
- **Kubernetes version**: 1.20+

### NVIDIA GPU Setup (if using GPUs)

```bash
# Install NVIDIA device plugin
helm repo add nvidia https://nvidia.github.io/k8s-device-plugin
helm repo update
helm install nvidia-device-plugin nvidia/nvidia-device-plugin --namespace kube-system

# Verify GPU availability
kubectl get nodes -L nvidia.com/gpu
```

## Installation

### 1. Add Helm Repository

```bash
# Add the repository (if using external repo)
helm repo add dpg https://charts.example.com/dpg
helm repo update
```

### 2. Create Namespace

```bash
# Create namespace for the application
kubectl create namespace agri-help
kubectl label namespace agri-help monitoring=enabled
```

### 3. Create Secrets (if using sealed-secrets)

```bash
# Create docker registry secret
kubectl create secret docker-registry docker-secret \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n agri-help

# Create API key secret
kubectl create secret generic api-keys \
  --from-literal=openrouter_api_key='your-api-key' \
  --from-literal=aws_access_key='your-access-key' \
  --from-literal=aws_secret_key='your-secret-key' \
  -n agri-help
```

### 4. Install the Helm Chart

```bash
# Dry-run to see what will be created
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help \
  --values ./helm/agri-help-app/values-dev.yaml \
  --dry-run --debug

# Actual installation
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help \
  --values ./helm/agri-help-app/values-dev.yaml

# Check installation status
helm status agri-help -n agri-help
```

## Configuration

### Environment-Specific Values

The chart supports multiple environment configurations:

#### Development (`values-dev.yaml`)
- Minimal resources
- Single replicas
- Debugging enabled
- No auto-scaling
- Local storage

#### Staging (`values-staging.yaml`)
- Medium resources
- 2 replicas
- Production-like configuration
- Basic auto-scaling
- Network policies

#### Production (`values-prod.yaml`)
- High availability
- 3+ replicas
- Optimized resources
- Advanced auto-scaling
- Complete monitoring
- Network policies enabled
- Pod disruption budgets

### Customizing Values

```bash
# Override specific values
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help \
  --set backend.replicaCount=3 \
  --set backend.image.tag=v1.2.0 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=api.example.com

# Use multiple values files
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help \
  -f values.yaml \
  -f values-prod.yaml \
  -f custom-values.yaml
```

### Key Configuration Options

```yaml
# Enable/disable services
backend:
  enabled: true
  replicaCount: 3
  image:
    tag: v1.2.0
  
frontend:
  enabled: true
  replicaCount: 2

# Resource configuration
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
    nvidia.com/gpu: "1"
  limits:
    cpu: 2000m
    memory: 4Gi
    nvidia.com/gpu: "1"

# Ingress configuration
ingress:
  enabled: true
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

## Deployment

### Using Terraform with Helm Provider

```hcl
# Deployment with Terraform
resource "helm_release" "agri_help" {
  name       = "agri-help"
  repository = "https://charts.example.com/dpg"
  chart      = "agri-help-app"
  namespace  = kubernetes_namespace.agri_help.metadata[0].name
  version    = "1.0.0"

  values = [
    file("${path.module}/helm/agri-help-app/values-prod.yaml")
  ]

  set {
    name  = "backend.replicaCount"
    value = 3
  }

  set {
    name  = "ingress.enabled"
    value = true
  }
}
```

### Upgrade Deployment

```bash
# Update chart values
helm upgrade agri-help ./helm/agri-help-app \
  --namespace agri-help \
  --values ./helm/agri-help-app/values-prod.yaml \
  --set backend.image.tag=v1.2.0

# Rollback if issues occur
helm rollback agri-help 1 -n agri-help

# List release history
helm history agri-help -n agri-help
```

### Uninstall Deployment

```bash
# Uninstall the release
helm uninstall agri-help -n agri-help

# Delete the namespace
kubectl delete namespace agri-help
```

## Monitoring

### Prometheus Integration

The charts include ServiceMonitor and PrometheusRule resources for monitoring:

```bash
# Install Prometheus Operator (if not already installed)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack

# Verify metrics collection
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Access: http://localhost:9090
```

### View Logs

```bash
# View logs from all pods
kubectl logs -n agri-help -l app=backend --all-containers=true -f

# View logs from specific pod
kubectl logs -n agri-help <pod-name> -f

# View previous logs (for crashed pods)
kubectl logs -n agri-help <pod-name> --previous
```

### Check Pod Status

```bash
# Get pod status
kubectl get pods -n agri-help

# Describe pod for events
kubectl describe pod -n agri-help <pod-name>

# Get resource usage
kubectl top pods -n agri-help
```

## Troubleshooting

### Common Issues

#### Pods not starting

```bash
# Check pod status
kubectl describe pod -n agri-help <pod-name>

# Check events
kubectl get events -n agri-help --sort-by='.lastTimestamp'

# Check resource availability
kubectl describe node <node-name>
```

#### Image pull failures

```bash
# Verify image pull secrets
kubectl get secrets -n agri-help

# Check docker registry access
kubectl run -it --rm debug --image=busybox --restart=Never -n agri-help -- sh
# Inside: wget https://docker.io -O - 2>&1 | head -20
```

#### Helm chart issues

```bash
# Validate chart syntax
helm lint ./helm/agri-help-app

# Check template rendering
helm template agri-help ./helm/agri-help-app \
  --values ./helm/agri-help-app/values-dev.yaml

# Diff with current deployment
helm diff upgrade agri-help ./helm/agri-help-app \
  --values ./helm/agri-help-app/values-prod.yaml
```

#### GPU not detected

```bash
# Check GPU availability
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, gpu: .status.allocatable | select(.["nvidia.com/gpu"] != null)}'

# Check GPU device plugin
kubectl logs -n kube-system -l app=nvidia-device-plugin -f

# Check resource allocation
kubectl get pods -n agri-help -o wide
kubectl describe pod -n agri-help <gpu-pod-name> | grep -A 10 "Limits"
```

### Debug Mode

Enable debug logging:

```bash
# Helm install with debug
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help \
  --values ./helm/agri-help-app/values-dev.yaml \
  --debug

# Set environment variable in values
env:
  DEBUG: "true"
  LOG_LEVEL: DEBUG

# Port forward to debug
kubectl port-forward -n agri-help svc/backend 8000:8000
curl http://localhost:8000/health
```

### Performance Tuning

```bash
# Monitor resource usage
watch -n 2 'kubectl top pods -n agri-help'

# Check HPA status
kubectl get hpa -n agri-help -w

# Adjust resource limits
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.limits.memory=8Gi \
  --set backend.resources.limits.cpu=4000m
```

## Best Practices

1. **Always use environment-specific values files**
2. **Implement NetworkPolicies for security**
3. **Enable resource quotas and limits**
4. **Use secrets management tools (sealed-secrets, external-secrets)**
5. **Implement health checks and probes**
6. **Enable monitoring and alerting**
7. **Use Pod Disruption Budgets**
8. **Implement RBAC policies**
9. **Use image registries with authentication**
10. **Regularly backup database volumes**

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/overview.html)
