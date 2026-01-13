# Multi-Cloud GPU Terraform - Helm Charts

Complete Helm charts for deploying Digital Public Goods (DPG) applications with GPU support across AWS, GCP, and Azure.

## 📚 Overview

This repository contains production-ready Helm charts for the **Agri-Help** application - a multi-service system consisting of:

- **Backend**: FastAPI RAG (Retrieval-Augmented Generation) engine with GPU support
- **Frontend**: Next.js web application
- **Databases**: PostgreSQL, Redis, Qdrant Vector Database
- **Services**: Transcription service, OAN UI service
- **Monitoring**: Prometheus, Grafana, alerting
- **Networking**: NGINX Ingress, TLS/SSL support

## 🚀 Quick Start

### Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- kubectl configured
- (Optional) GPU nodes with NVIDIA drivers

### Installation

```bash
# 1. Create namespace
kubectl create namespace agri-help-prod

# 2. Add Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 3. Install Agri-Help
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --values ./helm/agri-help-app/values-prod.yaml

# 4. Verify installation
helm status agri-help -n agri-help-prod
kubectl get pods -n agri-help-prod
```

## 📖 Documentation

### Core Guides
- **[HELM_SETUP.md](HELM_SETUP.md)** - Complete Helm setup guide, installation instructions, and configuration
- **[DEVELOPMENT_DEPLOYMENT.md](DEVELOPMENT_DEPLOYMENT.md)** - Development environment setup with local debugging
- **[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)** - Production deployment with high availability and security
- **[HELM_CICD_PIPELINE.md](HELM_CICD_PIPELINE.md)** - CI/CD pipelines for GitHub Actions and GitLab CI
- **[HELM_TROUBLESHOOTING.md](HELM_TROUBLESHOOTING.md)** - Troubleshooting guide and best practices

### Chart Structure

```
helm/
└── agri-help-app/
    ├── Chart.yaml                    # Chart metadata
    ├── values.yaml                   # Default values
    ├── values-dev.yaml               # Development overrides
    ├── values-staging.yaml           # Staging overrides
    ├── values-prod.yaml              # Production overrides
    └── templates/
        ├── _helpers.tpl              # Template helpers
        ├── NOTES.txt                 # Installation notes
        ├── backend-deployment.yaml   # Backend service
        ├── backend-service.yaml      # Backend networking
        ├── backend-ingress.yaml      # Backend ingress
        ├── backend-hpa.yaml          # Auto-scaling
        ├── backend-pdb.yaml          # Disruption budget
        ├── configmap.yaml            # Configuration
        ├── secret.yaml               # Secrets
        ├── rbac.yaml                 # RBAC policies
        └── network-policy.yaml       # Network policies
```

## 🔧 Configuration

### Environment-Specific Values

The chart supports three environments through dedicated values files:

#### Development (`values-dev.yaml`)
```bash
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-dev \
  --values ./helm/agri-help-app/values-dev.yaml
```
- Minimal resources (250m CPU, 256Mi memory)
- Single replica deployments
- Debug logging enabled
- No autoscaling
- Local storage

#### Staging (`values-staging.yaml`)
```bash
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-staging \
  --values ./helm/agri-help-app/values-staging.yaml
```
- Medium resources (500m CPU, 512Mi memory)
- 2 replicas per service
- Production-like configuration
- Basic autoscaling
- Network policies enabled

#### Production (`values-prod.yaml`)
```bash
helm install agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --values ./helm/agri-help-app/values-prod.yaml
```
- Optimized resources (1000m CPU, 2Gi memory)
- 3+ replicas per service
- High availability setup
- Advanced autoscaling
- Complete monitoring
- Pod disruption budgets
- Network policies
- Security hardening

### Custom Configuration

Override values at installation:

```bash
helm install agri-help ./helm/agri-help-app \
  --set backend.replicaCount=5 \
  --set backend.image.tag=v1.2.0 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=api.example.com
```

## 🐳 Services

### Backend (FastAPI)
- **Port**: 8000
- **GPU Support**: Yes (NVIDIA)
- **Replicas**: 1-5 (configurable)
- **Resources**: 250m-4000m CPU, 256Mi-8Gi memory
- **Health Checks**: Liveness + Readiness probes

### Frontend (Next.js)
- **Port**: 3000
- **Replicas**: 1-4 (configurable)
- **Resources**: 250m-1000m CPU, 256Mi-1Gi memory
- **Static Assets**: Served with CDN-ready caching

### Database Services
- **PostgreSQL**: Primary data storage
- **Redis**: Caching and session management
- **Qdrant**: Vector database for semantic search

### Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Dashboard visualization
- **ServiceMonitor**: Automatic scrape configuration

## 🔐 Security

The charts implement security best practices:

- ✅ Pod Security Context (non-root user, no privilege escalation)
- ✅ RBAC (Role-Based Access Control)
- ✅ Network Policies (ingress/egress control)
- ✅ Secret Management (sealed-secrets ready)
- ✅ Image Security (minimal base images, scanning)
- ✅ Resource Limits (CPU, memory constraints)
- ✅ Health Checks (liveness, readiness probes)

## 📊 Monitoring

### Prometheus Metrics
- HTTP request rates and latencies
- Container resource usage (CPU, memory)
- Application-specific metrics
- Database connection pool status

### Grafana Dashboards
- Service health overview
- Resource utilization trends
- Error rates and logs
- Performance metrics

### Alerting Rules
- Pod crash detection
- High resource usage
- Database connectivity issues
- Service availability

## 🚀 Deployment Methods

### 1. Direct Helm Commands
```bash
helm install agri-help ./helm/agri-help-app -n agri-help-prod
```

### 2. Terraform with Helm Provider
```hcl
resource "helm_release" "agri_help" {
  name      = "agri-help"
  chart     = "./helm/agri-help-app"
  namespace = kubernetes_namespace.agri_help.metadata[0].name
  
  values = [file("${path.module}/helm/agri-help-app/values-prod.yaml")]
}
```

### 3. GitOps with ArgoCD
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: agri-help
spec:
  source:
    repoURL: https://github.com/youorg/agri-help
    path: helm/agri-help-app
  destination:
    namespace: agri-help-prod
```

### 4. CI/CD Pipeline (GitHub Actions / GitLab CI)
See [HELM_CICD_PIPELINE.md](HELM_CICD_PIPELINE.md) for complete pipeline configurations.

## 🔄 Upgrade and Rollback

### Upgrade
```bash
# Upgrade to new version
helm upgrade agri-help ./helm/agri-help-app \
  --namespace agri-help-prod \
  --values ./helm/agri-help-app/values-prod.yaml

# Verify upgrade
helm status agri-help -n agri-help-prod
kubectl rollout status deployment -n agri-help-prod
```

### Rollback
```bash
# Rollback to previous version
helm rollback agri-help -n agri-help-prod

# Rollback to specific revision
helm rollback agri-help 5 -n agri-help-prod

# View release history
helm history agri-help -n agri-help-prod
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Enable autoscaling
helm upgrade agri-help ./helm/agri-help-app \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10

# Manual scaling
kubectl scale deployment backend -n agri-help-prod --replicas=5
```

### Resource Scaling
```bash
# Increase resource limits
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.limits.cpu=4000m \
  --set backend.resources.limits.memory=8Gi
```

## 🐛 Troubleshooting

See [HELM_TROUBLESHOOTING.md](HELM_TROUBLESHOOTING.md) for:
- Common issues and solutions
- Debug procedures
- Performance optimization
- Security hardening tips

Quick diagnostic commands:
```bash
# Pod status
kubectl get pods -n agri-help-prod -o wide

# Service endpoints
kubectl get endpoints -n agri-help-prod

# Recent events
kubectl get events -n agri-help-prod --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n agri-help-prod

# Logs
kubectl logs -n agri-help-prod -l app=backend -f
```

## 🌍 Multi-Cloud Support

### AWS EKS
```bash
# Create EKS cluster
eksctl create cluster --name agri-help-prod --region us-east-1

# Configure kubectl
aws eks update-kubeconfig --name agri-help-prod --region us-east-1
```

### Google Cloud GKE
```bash
# Create GKE cluster
gcloud container clusters create agri-help-prod --region us-central1

# Get credentials
gcloud container clusters get-credentials agri-help-prod --zone us-central1-a
```

### Microsoft Azure AKS
```bash
# Create AKS cluster
az aks create --resource-group agri-help --name agri-help-prod

# Get credentials
az aks get-credentials --resource-group agri-help --name agri-help-prod
```

## 📦 Versions

| Component | Version | Status |
|-----------|---------|--------|
| Chart | 1.0.0 | Stable |
| Kubernetes | 1.20+ | ✅ Tested |
| Helm | 3.0+ | ✅ Required |
| Backend | 2.0.0+ | ✅ Compatible |
| Frontend | 1.5.0+ | ✅ Compatible |

## 🤝 Contributing

### Adding New Services
1. Create deployment template in `templates/`
2. Add configuration to `values.yaml`
3. Update `Chart.yaml` dependencies
4. Document in relevant README

### Testing Changes
```bash
# Validate syntax
helm lint ./helm/agri-help-app

# Test rendering
helm template agri-help ./helm/agri-help-app

# Dry-run deployment
helm install agri-help ./helm/agri-help-app --dry-run --debug
```

## 📞 Support

For issues and questions:
1. Check [HELM_TROUBLESHOOTING.md](HELM_TROUBLESHOOTING.md)
2. Review Kubernetes documentation: https://kubernetes.io/docs/
3. Check Helm documentation: https://helm.sh/docs/
4. Review application logs: `kubectl logs -n agri-help-prod <pod>`

## 📄 License

This Helm chart is part of the Agri-Help project and follows the project's license terms.

## 🔗 Related Documentation

- [Terraform Infrastructure](README.md)
- [Development Deployment](DEVELOPMENT_DEPLOYMENT.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [CI/CD Pipeline](HELM_CICD_PIPELINE.md)
- [Troubleshooting Guide](HELM_TROUBLESHOOTING.md)

---

**Last Updated**: 2024
**Maintainer**: DevOps Team
**Repository**: https://github.com/youorg/multi-cloud-gpu-terraform
