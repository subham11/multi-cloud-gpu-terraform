# Helm Charts - Quick Reference Card

Quick reference commands and configurations for the Agri-Help Helm charts.

## 🚀 Quick Commands

### Installation

```bash
# Create namespace
kubectl create namespace agri-help-prod

# Install chart (basic)
helm install agri-help ./helm/agri-help-app -n agri-help-prod

# Install with custom values
helm install agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  -f values-prod.yaml

# Dry-run (test without deploying)
helm install agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  --dry-run --debug
```

### Verification

```bash
# Check installation
helm status agri-help -n agri-help-prod

# List all releases
helm list -n agri-help-prod

# Get current values
helm get values agri-help -n agri-help-prod

# Check pod status
kubectl get pods -n agri-help-prod

# View all resources
kubectl get all -n agri-help-prod
```

### Upgrade & Rollback

```bash
# Upgrade release
helm upgrade agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  -f values-prod.yaml

# View history
helm history agri-help -n agri-help-prod

# Rollback to previous
helm rollback agri-help -n agri-help-prod

# Rollback to specific revision
helm rollback agri-help 5 -n agri-help-prod

# Uninstall
helm uninstall agri-help -n agri-help-prod
```

## 📝 Common Values Overrides

```bash
# Override image tag
helm install agri-help ./helm/agri-help-app \
  --set backend.image.tag=v1.2.0

# Set replicas
helm install agri-help ./helm/agri-help-app \
  --set backend.replicaCount=3 \
  --set frontend.replicaCount=3

# Enable ingress
helm install agri-help ./helm/agri-help-app \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=api.example.com

# Enable autoscaling
helm install agri-help ./helm/agri-help-app \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=10

# Set resource limits
helm install agri-help ./helm/agri-help-app \
  --set backend.resources.limits.cpu=4000m \
  --set backend.resources.limits.memory=8Gi
```

## 🔍 Debugging Commands

```bash
# View pod logs
kubectl logs -n agri-help-prod <pod-name>

# Follow logs (live)
kubectl logs -n agri-help-prod <pod-name> -f

# View logs from all pods with label
kubectl logs -n agri-help-prod -l app=backend -f

# Get pod details
kubectl describe pod -n agri-help-prod <pod-name>

# Execute command in pod
kubectl exec -it -n agri-help-prod <pod-name> -- bash

# Port forward
kubectl port-forward -n agri-help-prod svc/backend 8000:8000
```

## 📊 Monitoring

```bash
# Check resource usage
kubectl top pods -n agri-help-prod
kubectl top nodes

# Watch pod status
kubectl get pods -n agri-help-prod -w

# Get events
kubectl get events -n agri-help-prod --sort-by='.lastTimestamp'

# View HPA status
kubectl get hpa -n agri-help-prod

# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## 🗂️ File Locations

```
helm/agri-help-app/
├── Chart.yaml                    # Chart metadata
├── values.yaml                   # Default values
├── values-dev.yaml               # Dev environment
├── values-staging.yaml           # Staging environment
├── values-prod.yaml              # Production environment
└── templates/
    ├── _helpers.tpl              # Helpers
    ├── NOTES.txt                 # Installation notes
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── backend-ingress.yaml
    ├── backend-hpa.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── rbac.yaml
    └── network-policy.yaml
```

## 🔐 Secrets & ConfigMaps

```bash
# Create secret
kubectl create secret generic app-secrets \
  --from-literal=api_key='value' \
  -n agri-help-prod

# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=info \
  -n agri-help-prod

# View secrets
kubectl get secrets -n agri-help-prod

# View ConfigMaps
kubectl get configmap -n agri-help-prod

# Edit secret
kubectl edit secret app-secrets -n agri-help-prod

# Edit ConfigMap
kubectl edit configmap app-config -n agri-help-prod
```

## 📦 Database Operations

```bash
# PostgreSQL
# List databases
kubectl exec -it -n agri-help-prod postgresql-0 -- \
  psql -U agri_user -l

# Connect to database
kubectl exec -it -n agri-help-prod postgresql-0 -- \
  psql -U agri_user agri_chatbot

# Backup database
kubectl exec -n agri-help-prod postgresql-0 -- \
  pg_dump -U agri_user agri_chatbot > backup.sql

# Restore database
kubectl exec -i -n agri-help-prod postgresql-0 -- \
  psql -U agri_user agri_chatbot < backup.sql

# Redis
# Connect to Redis
kubectl exec -it -n agri-help-prod redis-master-0 -- redis-cli

# Flush Redis cache
kubectl exec -n agri-help-prod redis-master-0 -- redis-cli FLUSHALL

# Check Redis memory
kubectl exec -n agri-help-prod redis-master-0 -- redis-cli INFO memory
```

## 🌐 Networking

```bash
# Check services
kubectl get svc -n agri-help-prod

# Check endpoints
kubectl get endpoints -n agri-help-prod

# Check ingress
kubectl get ingress -n agri-help-prod

# Get ingress IP/domain
kubectl get ingress -n agri-help-prod -o jsonpath='{.items[0].status.loadBalancer.ingress[0]}'

# Test service connectivity
kubectl exec -it -n agri-help-prod <pod> -- \
  curl http://service-name:port

# Check DNS
kubectl exec -it -n agri-help-prod <pod> -- \
  nslookup service-name
```

## 📋 Deployment Strategies

### Rolling Update
```bash
helm upgrade agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  --values values-prod.yaml
```

### Canary Deployment
```bash
# Deploy to staging first
helm install agri-help-staging ./helm/agri-help-app \
  -n agri-help-staging \
  -f values-staging.yaml

# Test thoroughly
# Then deploy to production
helm upgrade agri-help ./helm/agri-help-app \
  -n agri-help-prod
```

### Blue-Green Deployment
```bash
# Deploy new version (green)
helm install agri-help-v2 ./helm/agri-help-app \
  -n agri-help-prod \
  --set version=v2

# Switch traffic (update ingress/service selector)
kubectl patch service backend -n agri-help-prod \
  -p '{"spec":{"selector":{"version":"v2"}}}'

# Delete old version (blue)
helm uninstall agri-help-v1 -n agri-help-prod
```

## ⚙️ Scale Operations

```bash
# Scale deployment manually
kubectl scale deployment backend -n agri-help-prod --replicas=5

# View current replicas
kubectl get deployment -n agri-help-prod

# Enable autoscaling
helm upgrade agri-help ./helm/agri-help-app \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10

# Check HPA status
kubectl get hpa -n agri-help-prod -w
```

## 🔄 Maintenance Operations

```bash
# Restart deployment
kubectl rollout restart deployment backend -n agri-help-prod

# Check rollout status
kubectl rollout status deployment backend -n agri-help-prod

# View rollout history
kubectl rollout history deployment backend -n agri-help-prod

# Undo last deployment
kubectl rollout undo deployment backend -n agri-help-prod

# Undo to specific revision
kubectl rollout undo deployment backend -n agri-help-prod --to-revision=2
```

## 🧹 Cleanup Operations

```bash
# Delete pod (will be recreated)
kubectl delete pod -n agri-help-prod <pod-name>

# Delete all pods in deployment
kubectl delete pods -n agri-help-prod -l app=backend

# Delete namespace
kubectl delete namespace agri-help-prod

# Delete PVC
kubectl delete pvc -n agri-help-prod <pvc-name>

# Prune unused resources
kubectl delete pvc,pv -n agri-help-prod --all
```

## 📈 Performance Tuning

```bash
# Check resource usage
kubectl top pods -n agri-help-prod
kubectl top nodes

# View resource requests/limits
kubectl get pods -n agri-help-prod -o json | \
  jq '.items[] | {name: .metadata.name, resources: .spec.containers[].resources}'

# Increase limits
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.limits.cpu=4000m \
  --set backend.resources.limits.memory=8Gi
```

## 🛡️ Security Commands

```bash
# Check RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:agri-help-prod:agri-help

# View network policies
kubectl get networkpolicies -n agri-help-prod

# Get pod security context
kubectl get pod -n agri-help-prod <pod> -o yaml | grep -A 10 securityContext

# Scan image for vulnerabilities
trivy image agri-help-backend:v1.0.0

# Check image pull secrets
kubectl get secrets -n agri-help-prod -l type=kubernetes.io/dockercfg
```

## 📊 Validation Commands

```bash
# Validate Helm chart syntax
helm lint ./helm/agri-help-app --strict

# Render templates
helm template agri-help ./helm/agri-help-app -f values-prod.yaml

# Validate manifests
kubectl apply -f <manifest.yaml> --dry-run=client

# Check API availability
curl -k https://api.agri-help.io/health

# Check frontend
curl -k https://agri-help.io/
```

## 🆘 Emergency Commands

```bash
# Delete failing pod (will be recreated)
kubectl delete pod -n agri-help-prod <pod-name>

# Force delete stuck pod
kubectl delete pod -n agri-help-prod <pod-name> --grace-period=0 --force

# Clear failed pods
kubectl delete pod --field-selector=status.phase=Failed -n agri-help-prod

# Emergency rollback
helm rollback agri-help -n agri-help-prod

# Stop application (scale to 0)
kubectl scale deployment backend -n agri-help-prod --replicas=0

# Restart everything
kubectl delete pods --all -n agri-help-prod
```

## 📚 Environment-Specific Commands

### Development
```bash
helm install agri-help ./helm/agri-help-app \
  -n agri-help-dev \
  -f values-dev.yaml \
  --set backend.image.pullPolicy=Always
```

### Staging
```bash
helm install agri-help ./helm/agri-help-app \
  -n agri-help-staging \
  -f values-staging.yaml \
  --wait
```

### Production
```bash
helm install agri-help ./helm/agri-help-app \
  -n agri-help-prod \
  -f values-prod.yaml \
  --wait \
  --timeout=5m
```

## 🔗 Useful Endpoints (when port-forwarded)

```
# Backend API
http://localhost:8000
http://localhost:8000/docs (API documentation)
http://localhost:8000/health

# Frontend
http://localhost:3000

# Prometheus
http://localhost:9090

# Grafana
http://localhost:3000 (default user: admin)

# PostgreSQL
localhost:5432

# Redis
localhost:6379

# Qdrant
http://localhost:6333/health
```

## 💾 Important Files to Backup

```bash
# Backup configuration
tar czf helm-backup.tar.gz ./helm/

# Backup Helm release
helm get values agri-help -n agri-help-prod > helm-values-backup.yaml

# Backup database
kubectl exec -n agri-help-prod postgresql-0 -- \
  pg_dump -U agri_user agri_chatbot | gzip > db-backup.sql.gz

# Backup secrets
kubectl get secrets -n agri-help-prod -o yaml > secrets-backup.yaml
```

## 🆘 Getting Help

```bash
# Helm help
helm help
helm install --help
helm upgrade --help

# Kubectl help
kubectl help
kubectl logs --help
kubectl exec --help

# Get more information
kubectl explain deployment
kubectl explain pod
kubectl explain service
```

---

**Pro Tips**:
1. Always use `--dry-run --debug` before real deployments
2. Keep separate values files for each environment
3. Use descriptive release names
4. Tag images with versions, never use "latest" in production
5. Always backup before major changes
6. Test in dev → staging → production

**Quick Troubleshooting**:
1. Check pod status: `kubectl get pods -n agri-help-prod`
2. View logs: `kubectl logs -n agri-help-prod <pod>`
3. Describe pod: `kubectl describe pod -n agri-help-prod <pod>`
4. Check events: `kubectl get events -n agri-help-prod`
5. Check resources: `kubectl top pods -n agri-help-prod`
