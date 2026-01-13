# CI/CD Pipeline for Helm Charts

This guide provides comprehensive CI/CD pipeline configurations for automated testing, building, and deploying Helm charts.

## Table of Contents

1. [GitHub Actions Pipeline](#github-actions-pipeline)
2. [GitLab CI Pipeline](#gitlab-ci-pipeline)
3. [Chart Testing and Validation](#chart-testing-and-validation)
4. [Automated Deployments](#automated-deployments)
5. [Rollback Procedures](#rollback-procedures)

## GitHub Actions Pipeline

### Helm Chart Validation and Testing

Create `.github/workflows/helm-chart-validation.yml`:

```yaml
name: Helm Chart Validation

on:
  pull_request:
    paths:
      - 'helm/**'
      - '.github/workflows/helm-chart-validation.yml'
  push:
    branches:
      - main
      - develop
    paths:
      - 'helm/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Helm
        uses: azure/setup-helm@v3
        with:
          version: 'latest'

      - name: Lint Helm chart
        run: |
          helm lint ./helm/agri-help-app \
            --strict \
            --values ./helm/agri-help-app/values.yaml

      - name: Validate chart schema
        run: |
          helm template agri-help ./helm/agri-help-app \
            --values ./helm/agri-help-app/values-dev.yaml \
            > /tmp/rendered-dev.yaml
          
          helm template agri-help ./helm/agri-help-app \
            --values ./helm/agri-help-app/values-prod.yaml \
            > /tmp/rendered-prod.yaml

      - name: Check YAML syntax
        run: |
          docker run --rm -v $(pwd):/workspace \
            cytopia/yamllint:latest \
            /workspace/helm/

      - name: Scan templates with kubesec
        run: |
          docker run --rm -v $(pwd):/workspace \
            kubesec/kubesec:latest \
            scan /workspace/helm/agri-help-app/templates/*.yaml

      - name: Install chart-testing
        run: |
          curl https://raw.githubusercontent.com/helm/chart-testing/main/ct/install.sh | bash

      - name: Run chart-testing
        run: |
          ct lint --config .ct.yaml

  test-install:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Create Kind cluster
        uses: helm/kind-action@v1.7.0
        with:
          cluster_name: test-cluster
          config: |
            kind: Cluster
            apiVersion: kind.x-k8s.io/v1alpha4
            nodes:
            - role: control-plane
            - role: worker
            - role: worker

      - name: Set up Helm
        uses: azure/setup-helm@v3

      - name: Add Helm repositories
        run: |
          helm repo add postgresql https://charts.bitnami.com/bitnami
          helm repo add redis https://charts.bitnami.com/bitnami
          helm repo update

      - name: Install chart
        run: |
          helm install test-release ./helm/agri-help-app \
            --namespace test \
            --create-namespace \
            --values ./helm/agri-help-app/values-dev.yaml \
            --wait --timeout 5m

      - name: Test chart deployment
        run: |
          kubectl rollout status deployment -n test --timeout=5m
          kubectl get all -n test

      - name: Run smoke tests
        run: |
          kubectl run test-pod \
            --image=python:3.9 \
            --restart=Never \
            -n test \
            --rm -i \
            -- python -c "
          import subprocess
          import json
          result = subprocess.run(['kubectl', 'get', 'svc', '-n', 'test', '-o', 'json'], 
                                capture_output=True, text=True)
          services = json.loads(result.stdout)
          assert len(services['items']) > 0, 'No services found'
          print('Smoke tests passed!')
          "
```

### Build and Push Docker Images

Create `.github/workflows/build-and-push-images.yml`:

```yaml
name: Build and Push Docker Images

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'backend/**'
      - 'frontend/**'
      - '.github/workflows/build-and-push-images.yml'
  pull_request:
    paths:
      - 'backend/**'
      - 'frontend/**'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - dockerfile: backend/Dockerfile
            context: backend
            image: agri-help-backend
          - dockerfile: frontend/Dockerfile
            context: frontend
            image: agri-help-frontend

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        if: github.event_name == 'push'
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./${{ matrix.context }}
          file: ./${{ matrix.dockerfile }}
          push: ${{ github.event_name == 'push' }}
          tags: |
            ${{ secrets.DOCKER_REGISTRY }}/${{ matrix.image }}:${{ github.sha }}
            ${{ secrets.DOCKER_REGISTRY }}/${{ matrix.image }}:latest
          cache-from: type=registry,ref=${{ secrets.DOCKER_REGISTRY }}/${{ matrix.image }}:buildcache
          cache-to: type=registry,ref=${{ secrets.DOCKER_REGISTRY }}/${{ matrix.image }}:buildcache,mode=max

      - name: Scan image with Trivy
        if: github.event_name == 'push'
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ secrets.DOCKER_REGISTRY }}/${{ matrix.image }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security tab
        if: github.event_name == 'push'
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

### Deploy to Development/Staging/Production

Create `.github/workflows/helm-deploy.yml`:

```yaml
name: Deploy with Helm

on:
  workflow_run:
    workflows: ["Build and Push Docker Images"]
    types: [completed]
    branches: [main, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    strategy:
      matrix:
        environment:
          - name: development
            cluster: agri-help-dev
            region: us-east-1
            values-file: values-dev.yaml
          - name: staging
            cluster: agri-help-staging
            region: us-east-1
            values-file: values-staging.yaml
          - name: production
            cluster: agri-help-prod
            region: us-east-1
            values-file: values-prod.yaml
            require-approval: true

    environment:
      name: ${{ matrix.environment.name }}
      url: https://${{ matrix.environment.name }}.agri-help.io

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ matrix.environment.region }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig \
            --name ${{ matrix.environment.cluster }} \
            --region ${{ matrix.environment.region }}

      - name: Set up Helm
        uses: azure/setup-helm@v3

      - name: Add Helm repositories
        run: |
          helm repo add postgresql https://charts.bitnami.com/bitnami
          helm repo add redis https://charts.bitnami.com/bitnami
          helm repo update

      - name: Get image tag
        id: image-tag
        run: |
          echo "tag=${{ github.event.workflow_run.head_commit.id }}" >> $GITHUB_OUTPUT

      - name: Upgrade Helm release
        run: |
          helm upgrade --install agri-help ./helm/agri-help-app \
            --namespace agri-help-${{ matrix.environment.name }} \
            --create-namespace \
            --values ./helm/agri-help-app/values.yaml \
            --values ./helm/agri-help-app/${{ matrix.environment.values-file }} \
            --set backend.image.tag=${{ steps.image-tag.outputs.tag }} \
            --set frontend.image.tag=${{ steps.image-tag.outputs.tag }} \
            --wait \
            --timeout 5m

      - name: Verify deployment
        run: |
          kubectl rollout status deployment -n agri-help-${{ matrix.environment.name }} --timeout=5m
          kubectl get all -n agri-help-${{ matrix.environment.name }}

      - name: Run smoke tests
        run: |
          kubectl run smoke-test \
            --image=curlimages/curl \
            --restart=Never \
            -n agri-help-${{ matrix.environment.name }} \
            --rm -i \
            -- sh -c "
            curl -f http://backend/health || exit 1
            curl -f http://frontend || exit 1
            "

      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v1.24.0
        with:
          payload: |
            {
              "text": "Helm deployment to ${{ matrix.environment.name }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Environment: ${{ matrix.environment.name }}\nStatus: ${{ job.status }}\nCommit: ${{ github.event.workflow_run.head_commit.message }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## GitLab CI Pipeline

Create `.gitlab-ci.yml`:

```yaml
stages:
  - validate
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  HELM_VERSION: "3.12.0"
  DOCKER_REGISTRY: "registry.gitlab.com/$CI_PROJECT_PATH"

# Helm chart validation
helm-lint:
  stage: validate
  image: alpine/helm:$HELM_VERSION
  script:
    - helm lint ./helm/agri-help-app --strict
  only:
    - merge_requests
    - main
    - develop
  artifacts:
    reports:
      dotenv: build.env

helm-template:
  stage: validate
  image: alpine/helm:$HELM_VERSION
  script:
    - helm template agri-help ./helm/agri-help-app -f ./helm/agri-help-app/values-dev.yaml
    - helm template agri-help ./helm/agri-help-app -f ./helm/agri-help-app/values-prod.yaml
  only:
    - merge_requests
    - main
    - develop

yamllint:
  stage: validate
  image: cytopia/yamllint:latest
  script:
    - yamllint ./helm/
  only:
    - merge_requests
    - main
    - develop

kubesec:
  stage: test
  image: kubesec/kubesec:latest
  script:
    - kubesec scan ./helm/agri-help-app/templates/*.yaml
  only:
    - merge_requests
    - main
    - develop

chart-testing:
  stage: test
  image: quay.io/helmpack/chart-testing:latest
  script:
    - ct lint --config .ct.yaml
  only:
    - merge_requests
    - main
    - develop

# Build Docker images
build-backend:
  stage: build
  image: docker:latest
  services:
    - docker:latest
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -f backend/Dockerfile -t $DOCKER_REGISTRY/agri-help-backend:$CI_COMMIT_SHA backend/
    - docker push $DOCKER_REGISTRY/agri-help-backend:$CI_COMMIT_SHA
    - docker tag $DOCKER_REGISTRY/agri-help-backend:$CI_COMMIT_SHA $DOCKER_REGISTRY/agri-help-backend:latest
    - docker push $DOCKER_REGISTRY/agri-help-backend:latest
  only:
    - main
    - develop
  artifacts:
    reports:
      dotenv: build.env

build-frontend:
  stage: build
  image: docker:latest
  services:
    - docker:latest
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -f frontend/Dockerfile -t $DOCKER_REGISTRY/agri-help-frontend:$CI_COMMIT_SHA frontend/
    - docker push $DOCKER_REGISTRY/agri-help-frontend:$CI_COMMIT_SHA
    - docker tag $DOCKER_REGISTRY/agri-help-frontend:$CI_COMMIT_SHA $DOCKER_REGISTRY/agri-help-frontend:latest
    - docker push $DOCKER_REGISTRY/agri-help-frontend:latest
  only:
    - main
    - develop

# Deploy to development
deploy-development:
  stage: deploy
  image: alpine/helm:$HELM_VERSION
  before_script:
    - mkdir -p $HOME/.kube
    - echo $KUBE_CONFIG_DEV | base64 -d > $HOME/.kube/config
    - helm repo add bitnami https://charts.bitnami.com/bitnami
    - helm repo update
  script:
    - helm upgrade --install agri-help ./helm/agri-help-app
        --namespace agri-help-dev
        --create-namespace
        --values ./helm/agri-help-app/values-dev.yaml
        --set backend.image.repository=$DOCKER_REGISTRY/agri-help-backend
        --set backend.image.tag=$CI_COMMIT_SHA
        --set frontend.image.repository=$DOCKER_REGISTRY/agri-help-frontend
        --set frontend.image.tag=$CI_COMMIT_SHA
        --wait
        --timeout 5m
    - kubectl rollout status deployment -n agri-help-dev --timeout=5m
  environment:
    name: development
    url: https://dev.agri-help.io
  only:
    - develop
  dependencies:
    - build-backend
    - build-frontend

# Deploy to staging
deploy-staging:
  stage: deploy
  image: alpine/helm:$HELM_VERSION
  before_script:
    - mkdir -p $HOME/.kube
    - echo $KUBE_CONFIG_STAGING | base64 -d > $HOME/.kube/config
    - helm repo add bitnami https://charts.bitnami.com/bitnami
    - helm repo update
  script:
    - helm upgrade --install agri-help ./helm/agri-help-app
        --namespace agri-help-staging
        --create-namespace
        --values ./helm/agri-help-app/values-staging.yaml
        --set backend.image.repository=$DOCKER_REGISTRY/agri-help-backend
        --set backend.image.tag=$CI_COMMIT_SHA
        --set frontend.image.repository=$DOCKER_REGISTRY/agri-help-frontend
        --set frontend.image.tag=$CI_COMMIT_SHA
        --wait
        --timeout 5m
    - kubectl rollout status deployment -n agri-help-staging --timeout=5m
  environment:
    name: staging
    url: https://staging.agri-help.io
  only:
    - main
  dependencies:
    - build-backend
    - build-frontend

# Deploy to production (manual approval required)
deploy-production:
  stage: deploy
  image: alpine/helm:$HELM_VERSION
  before_script:
    - mkdir -p $HOME/.kube
    - echo $KUBE_CONFIG_PROD | base64 -d > $HOME/.kube/config
    - helm repo add bitnami https://charts.bitnami.com/bitnami
    - helm repo update
  script:
    - helm upgrade --install agri-help ./helm/agri-help-app
        --namespace agri-help-prod
        --create-namespace
        --values ./helm/agri-help-app/values-prod.yaml
        --set backend.image.repository=$DOCKER_REGISTRY/agri-help-backend
        --set backend.image.tag=$CI_COMMIT_SHA
        --set frontend.image.repository=$DOCKER_REGISTRY/agri-help-frontend
        --set frontend.image.tag=$CI_COMMIT_SHA
        --wait
        --timeout 5m
    - kubectl rollout status deployment -n agri-help-prod --timeout=5m
  environment:
    name: production
    url: https://agri-help.io
    kubernetes:
      namespace: agri-help-prod
  only:
    - main
  when: manual
  dependencies:
    - build-backend
    - build-frontend
```

## Chart Testing and Validation

### Chart Testing Configuration

Create `.ct.yaml`:

```yaml
# Chart-testing configuration
chart-testing:
  validate-maintainers: true
  validate-values: true

# Lint configurations
lint:
  strict: true

# Testing options
testing:
  # Upgrade testing
  upgrade: true
  # Install testing
  install: true

# Reporting
reporting:
  # Junit report output
  junit: true
```

### Security Scanning

Create `scripts/scan-charts.sh`:

```bash
#!/bin/bash

set -e

CHART_PATH="./helm/agri-help-app"
SCAN_RESULTS="./scan-results"

mkdir -p "$SCAN_RESULTS"

echo "Starting Helm chart security scan..."

# 1. Scan with Kubesec
echo "Scanning with Kubesec..."
helm template agri-help "$CHART_PATH" | \
  docker run --rm -i kubesec/kubesec:latest scan - | \
  tee "$SCAN_RESULTS/kubesec-report.json"

# 2. Scan with Trivy
echo "Scanning with Trivy..."
helm template agri-help "$CHART_PATH" | \
  docker run --rm -i aquasec/trivy config - | \
  tee "$SCAN_RESULTS/trivy-report.txt"

# 3. Scan with Snyk (if configured)
if command -v snyk &> /dev/null; then
  echo "Scanning with Snyk..."
  snyk helm test "$CHART_PATH" --json > "$SCAN_RESULTS/snyk-report.json"
fi

echo "Scan complete. Results saved in $SCAN_RESULTS"
```

## Automated Deployments

### Rollback Procedures

Create `scripts/rollback-helm.sh`:

```bash
#!/bin/bash

RELEASE="${1:-agri-help}"
NAMESPACE="${2:-agri-help-prod}"
REVISION="${3:-0}"  # 0 means previous

echo "Rolling back Helm release: $RELEASE in namespace: $NAMESPACE"

# Get current revision
CURRENT_REVISION=$(helm list -n "$NAMESPACE" -o json | jq -r ".[] | select(.name==\"$RELEASE\") | .revision")
echo "Current revision: $CURRENT_REVISION"

# Perform rollback
helm rollback "$RELEASE" "$REVISION" -n "$NAMESPACE" --wait

# Verify rollback
kubectl rollout status deployment -n "$NAMESPACE" --timeout=5m

echo "Rollback completed successfully"

# Send notification
curl -X POST "$SLACK_WEBHOOK_URL" -H 'Content-type: application/json' \
  -d "{
    \"text\": \"Helm rollback completed\",
    \"blocks\": [{
      \"type\": \"section\",
      \"text\": {
        \"type\": \"mrkdwn\",
        \"text\": \"Release: $RELEASE\nNamespace: $NAMESPACE\nRevision: $CURRENT_REVISION -> $REVISION\"
      }
    }]
  }"
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Testing](https://github.com/helm/chart-testing)
