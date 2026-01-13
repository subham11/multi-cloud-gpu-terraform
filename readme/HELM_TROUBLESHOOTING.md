# Helm Charts - Troubleshooting and Best Practices Guide

This guide provides solutions to common issues and best practices for managing Helm charts in production.

## Table of Contents

1. [Troubleshooting](#troubleshooting)
2. [Best Practices](#best-practices)
3. [Performance Optimization](#performance-optimization)
4. [Security Hardening](#security-hardening)
5. [Monitoring and Debugging](#monitoring-and-debugging)

## Troubleshooting

### Pod Issues

#### Pods Not Starting

**Symptom**: Pods stuck in `Pending` or `ImagePullBackOff` state

```bash
# 1. Check pod status
kubectl describe pod -n agri-help-prod <pod-name>

# 2. Check events
kubectl get events -n agri-help-prod --sort-by='.lastTimestamp' | tail -20

# 3. Check resource availability
kubectl describe nodes

# 4. Check for node affinity issues
kubectl get pods -n agri-help-prod -o wide
```

**Solutions**:
- Check cluster resource availability
- Verify image pull secrets
- Check node selectors and affinity rules
- Verify storage class availability

#### Pods Crash Looping

**Symptom**: Pod continuously crashes and restarts

```bash
# 1. Check logs
kubectl logs -n agri-help-prod <pod-name> --previous
kubectl logs -n agri-help-prod <pod-name> -f

# 2. Check liveness/readiness probes
kubectl get pod -n agri-help-prod <pod-name> -o yaml | grep -A 20 "livenessProbe"

# 3. Get exit code
kubectl describe pod -n agri-help-prod <pod-name> | grep "Last State"
```

**Solutions**:
- Check application logs for errors
- Verify health check endpoints are working
- Check resource limits not being exceeded
- Verify environment variables and secrets are set

#### High Memory/CPU Usage

**Symptom**: Pods being killed due to OOMKilled or CPU throttling

```bash
# 1. Check resource usage
kubectl top pods -n agri-help-prod
kubectl top nodes

# 2. Check resource limits
kubectl get pods -n agri-help-prod -o yaml | grep -A 5 "resources:"

# 3. Check for memory leaks
kubectl exec -n agri-help-prod <pod-name> -- free -m
kubectl exec -n agri-help-prod <pod-name> -- ps aux
```

**Solutions**:
```bash
# Increase resource limits
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.limits.memory=8Gi \
  --set backend.resources.limits.cpu=4000m

# Enable autoscaling
helm upgrade agri-help ./helm/agri-help-app \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=10
```

### Deployment Issues

#### Helm Chart Installation Fails

```bash
# 1. Validate chart
helm lint ./helm/agri-help-app --strict

# 2. Check template rendering
helm template agri-help ./helm/agri-help-app --values values-prod.yaml > rendered.yaml

# 3. Dry-run installation
helm install agri-help ./helm/agri-help-app --dry-run --debug

# 4. Check for YAML syntax errors
kubectl apply -f rendered.yaml --dry-run=client
```

**Common Solutions**:
- Fix chart syntax errors
- Verify all required dependencies are installed
- Check resource quotas and limits
- Verify RBAC permissions

#### Upgrade Fails

```bash
# 1. Check upgrade status
helm status agri-help -n agri-help-prod

# 2. Get upgrade history
helm history agri-help -n agri-help-prod

# 3. Check rollout status
kubectl rollout status deployment -n agri-help-prod

# 4. Check events
kubectl get events -n agri-help-prod --sort-by='.lastTimestamp'
```

**Solutions**:
```bash
# Rollback to previous version
helm rollback agri-help -n agri-help-prod

# Rollback to specific revision
helm rollback agri-help 5 -n agri-help-prod

# Check what went wrong
kubectl describe deployment -n agri-help-prod
```

### Database Issues

#### PostgreSQL Connection Errors

```bash
# 1. Check PostgreSQL pod
kubectl get pods -n agri-help-prod -l app=postgresql

# 2. Check PostgreSQL logs
kubectl logs -n agri-help-prod -l app=postgresql -f

# 3. Test connection
kubectl exec -it -n agri-help-prod <backend-pod> -- \
  python -c "import psycopg2; conn = psycopg2.connect('dbname=agri_chatbot user=agri_user host=postgresql'); print('Connected')"

# 4. Check secrets
kubectl get secret -n agri-help-prod postgres-secret -o yaml
```

**Solutions**:
```bash
# Restart PostgreSQL
kubectl rollout restart deployment postgresql -n agri-help-prod

# Check service connectivity
kubectl exec -n agri-help-prod <pod> -- nc -zv postgresql 5432

# Verify credentials
kubectl get secret -n agri-help-prod postgres-secret -o jsonpath='{.data.password}' | base64 -d
```

#### Redis Connection Errors

```bash
# 1. Check Redis pod
kubectl get pods -n agri-help-prod -l app=redis

# 2. Check Redis logs
kubectl logs -n agri-help-prod -l app=redis -f

# 3. Test connection
kubectl exec -it -n agri-help-prod <backend-pod> -- \
  python -c "import redis; r = redis.Redis(host='redis-master'); print(r.ping())"
```

**Solutions**:
```bash
# Restart Redis
kubectl rollout restart deployment redis -n agri-help-prod

# Clear Redis cache
kubectl exec -it -n agri-help-prod <redis-pod> -- redis-cli FLUSHALL

# Check memory usage
kubectl exec -it -n agri-help-prod <redis-pod> -- redis-cli INFO memory
```

### Network Issues

#### DNS Resolution Failures

```bash
# 1. Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n agri-help-prod -- nslookup kubernetes.default

# 2. Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 3. Test service connectivity
kubectl exec -n agri-help-prod <pod> -- nslookup backend.agri-help-prod.svc.cluster.local
```

**Solutions**:
```bash
# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Check DNS policy in pod
kubectl get pod -n agri-help-prod <pod> -o yaml | grep -A 5 "dnsPolicy"
```

#### Service Connectivity Issues

```bash
# 1. Check service
kubectl get svc -n agri-help-prod

# 2. Check endpoints
kubectl get endpoints -n agri-help-prod

# 3. Test connectivity
kubectl exec -n agri-help-prod <pod> -- nc -zv backend 8000
```

**Solutions**:
```bash
# Verify service selector matches pods
kubectl get svc -n agri-help-prod -o yaml | grep selector -A 5

# Check network policies
kubectl get networkpolicies -n agri-help-prod

# Verify pod IPs
kubectl get pods -n agri-help-prod -o wide
```

### Image Issues

#### Image Pull Failures

```bash
# 1. Check image pull secrets
kubectl get secrets -n agri-help-prod

# 2. Check pod events
kubectl describe pod -n agri-help-prod <pod-name> | grep -A 10 "Events:"

# 3. Test image pull
docker pull <image-name>
```

**Solutions**:
```bash
# Create image pull secret
kubectl create secret docker-registry docker-secret \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n agri-help-prod

# Link to service account
kubectl patch serviceaccount agri-help -n agri-help-prod \
  -p '{"imagePullSecrets": [{"name": "docker-secret"}]}'

# Verify secret
kubectl get secret docker-secret -n agri-help-prod -o yaml
```

## Best Practices

### Chart Development

1. **Use semantic versioning**
   ```yaml
   # Chart.yaml
   version: 1.2.3  # Major.Minor.Patch
   appVersion: 2.1.0
   ```

2. **Document all values**
   ```yaml
   # In values.yaml, document every option
   # Enable/disable feature X
   feature:
     enabled: true
   ```

3. **Set resource limits**
   ```yaml
   resources:
     requests:
       cpu: 250m
       memory: 256Mi
     limits:
       cpu: 500m
       memory: 512Mi
   ```

4. **Use probes**
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8000
     initialDelaySeconds: 30
     periodSeconds: 10
   ```

5. **Implement RBAC**
   ```yaml
   rbac:
     create: true
     serviceAccount:
       create: true
   ```

### Deployment

1. **Use environment-specific values files**
   ```bash
   helm upgrade --install agri-help ./helm/agri-help-app \
     -f values.yaml \
     -f values-prod.yaml
   ```

2. **Always do dry-runs before deployment**
   ```bash
   helm install agri-help ./helm/agri-help-app \
     --dry-run --debug
   ```

3. **Use wait flag for stability**
   ```bash
   helm upgrade --install agri-help ./helm/agri-help-app \
     --wait --timeout 5m
   ```

4. **Pin image tags in production**
   ```yaml
   image:
     tag: "v1.2.3"  # Never use "latest"
   ```

5. **Use namespace isolation**
   ```bash
   kubectl create namespace agri-help-prod
   helm install agri-help ./helm/agri-help-app \
     --namespace agri-help-prod
   ```

### Configuration

1. **Use ConfigMaps for application config**
   ```yaml
   configMap:
     enabled: true
     data:
       ENVIRONMENT: production
       LOG_LEVEL: info
   ```

2. **Use Secrets for sensitive data**
   ```bash
   kubectl create secret generic app-secrets \
     --from-literal=api_key='...' \
     -n agri-help-prod
   ```

3. **Never hardcode secrets in values.yaml**
4. **Use external secrets management tools** (sealed-secrets, external-secrets)

### Monitoring

1. **Enable ServiceMonitor for Prometheus**
   ```yaml
   serviceMonitor:
     enabled: true
     interval: 30s
   ```

2. **Set up alerting rules**
   ```yaml
   prometheusRule:
     enabled: true
   ```

3. **Configure pod monitoring**
   ```yaml
   podAnnotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "8000"
     prometheus.io/path: "/metrics"
   ```

## Performance Optimization

### Resource Tuning

```bash
# 1. Monitor current usage
kubectl top pods -n agri-help-prod

# 2. Adjust resource requests/limits
helm upgrade agri-help ./helm/agri-help-app \
  --set backend.resources.requests.cpu=1000m \
  --set backend.resources.requests.memory=2Gi

# 3. Enable HPA
helm upgrade agri-help ./helm/agri-help-app \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10
```

### Database Optimization

```bash
# PostgreSQL
- Configure shared_buffers, work_mem, effective_cache_size
- Enable autovacuum
- Create appropriate indexes

# Redis
- Monitor memory usage
- Configure eviction policy
- Enable persistence if needed

# Qdrant
- Tune vector search parameters
- Configure replication for HA
```

### Caching Strategies

```yaml
# Use Redis for application-level caching
redis:
  enabled: true
  replica:
    replicaCount: 2
  persistence:
    enabled: true
    size: 10Gi
```

## Security Hardening

### Network Security

```yaml
# Enable network policies
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
```

### RBAC

```yaml
# Minimize service account permissions
rbac:
  create: true
  serviceAccount:
    create: true
```

### Pod Security

```yaml
# Run as non-root
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### Image Security

```bash
# Scan images for vulnerabilities
trivy image agri-help-backend:v1.0.0

# Use minimal base images
FROM python:3.9-slim

# Don't run as root
USER 1000
```

### Secret Management

```bash
# Use sealed-secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Seal secrets
echo -n mypassword | kubectl create secret generic mysecret --dry-run=client --from-file=/dev/stdin -o yaml | \
  kubeseal --format yaml > mysealedsecret.yaml
```

## Monitoring and Debugging

### Enable Debug Logging

```bash
# 1. Set log level to DEBUG
helm upgrade agri-help ./helm/agri-help-app \
  --set env.LOG_LEVEL=DEBUG

# 2. View logs
kubectl logs -n agri-help-prod -f -l app=backend

# 3. View logs from specific pod
kubectl logs -n agri-help-prod <pod-name> -f

# 4. View previous logs (crashed pod)
kubectl logs -n agri-help-prod <pod-name> --previous
```

### Port Forwarding for Debugging

```bash
# Backend
kubectl port-forward -n agri-help-prod svc/backend 8000:8000

# Database
kubectl port-forward -n agri-help-prod svc/postgresql 5432:5432

# Redis
kubectl port-forward -n agri-help-prod svc/redis-master 6379:6379

# Qdrant
kubectl port-forward -n agri-help-prod svc/qdrant 6333:6333
```

### Exec into Pods

```bash
# Execute command in pod
kubectl exec -it -n agri-help-prod <pod-name> -- bash

# Execute specific command
kubectl exec -n agri-help-prod <pod-name> -- python -c "print('Hello')"

# Execute as specific user
kubectl exec -it -n agri-help-prod <pod-name> --user root -- bash
```

### Check Application Metrics

```bash
# View Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Then access http://localhost:9090/targets

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up{job="kubernetes-apiservers"}'
```

## References

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Helm Troubleshooting](https://helm.sh/docs/faq/)
- [Debugging Kubernetes Pods](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-pod-replication-controller/)
