# CI/CD Pipeline Complete Workflow Guide

End-to-end guide for understanding and using the Jenkins CI/CD pipeline for automated testing, code coverage enforcement, and deployment.

## Overview

This CI/CD pipeline implements **automatic and manual deployment workflows** with the following key features:

| Feature | Details |
|---------|---------|
| **Automatic Triggers** | GitHub webhooks on main branch push/merge |
| **Manual Triggers** | Parameterized builds for testing feature branches |
| **Test Enforcement** | Unit tests must pass before deployment |
| **Coverage Threshold** | 85% code coverage required for deployment |
| **Health Checks** | Automatic post-deployment verification |
| **Reporting** | Build and deployment reports generated |

---

## Pipeline Architecture

```
GitHub Repository
    ↓
GitHub Webhook (on push to main)
    ↓
Jenkins Trigger
    ↓
Pipeline Stages:
    1. Initialization
    2. Checkout (clone repo)
    3. Verify Environment (Node.js version check)
    4. Install Dependencies (npm ci)
    5. Run Tests & Coverage (npm test --coverage)
    6. Parse Coverage (extract % metrics)
    7. Coverage Threshold Check (85% enforcement)
    8. Build (npm run build)
    9. Deploy (main branch only)
    10. Health Check (verify deployment)
    11. Report Generation
    ↓
Deployment Decision:
    ✓ Coverage ≥ 85% OR 0 tests → DEPLOY
    ✗ Coverage < 85% → FAIL (block deployment)
    ✓ Health check passes → SUCCESS
    ✗ Health check fails → FAILURE
```

---

## Pipeline Stages Explained

### Stage 1: Initialization

**Purpose**: Set up build environment

```
✓ Create workspace
✓ Log build information
✓ Display branch and timestamp
```

### Stage 2: Checkout

**Purpose**: Clone repository and verify source code

```groovy
git clone https://github.com/the-swag-coder/oan-ui-service.git
```

**Actions**:
- Clone specified branch
- Display Git log (last commit)
- Show repository status

### Stage 3: Verify Node.js

**Purpose**: Ensure correct runtime version

```bash
node -v  # Display Node.js version
npm -v   # Display npm version

# Verify: Node.js v16+ required
```

**Exit on failure**: Build fails if Node.js < v16

### Stage 4: Install Dependencies

**Purpose**: Install npm packages

```bash
npm ci --prefer-offline --no-audit
```

**Why `npm ci`**:
- Installs exact versions from `package-lock.json`
- More reliable than `npm install` for CI/CD
- Fails if lock file is out of sync

### Stage 5: Run Tests & Coverage

**Purpose**: Execute unit tests with coverage reporting

```bash
npm test -- --coverage --watchAll=false
```

**Output**:
```
 PASS  src/components/TextToSpeech.test.tsx
 PASS  src/components/Transcribe.test.tsx
 PASS  src/api/speechApi.test.ts

Test Suites: 3 passed, 3 total
Tests:       42 passed, 42 total
Coverage summary:
  Statements   : 92.3%
  Branches     : 88.5%
  Functions    : 91.2%
  Lines        : 93.1%
```

**Exit on failure**: Build fails if tests don't pass

### Stage 6: Parse Coverage

**Purpose**: Extract code coverage percentage

```bash
# Look for coverage report:
coverage/coverage-final.json
coverage/lcov.json

# Extract statements coverage percentage
```

**Coverage Metrics**:
- **Statements**: % of code executed
- **Branches**: % of if/else branches tested
- **Functions**: % of functions called
- **Lines**: % of lines executed

### Stage 7: Coverage Threshold Check

**Purpose**: Enforce 85% coverage requirement

```
IF coverage ≥ 85%:
    echo "✓ COVERAGE THRESHOLD MET"
    Proceed to Build stage
    
ELIF coverage < 85%:
    echo "✗ COVERAGE BELOW THRESHOLD"
    Block deployment
    Exit build with FAILURE
    
ELIF 0 tests found:
    echo "⚠ NO TESTS WRITTEN"
    Allow deployment (no coverage requirement)
    Proceed to Build stage
```

**Coverage Rules**:
| Scenario | Action |
|----------|--------|
| Coverage ≥ 85% | Deploy |
| Coverage < 85% | FAIL - Block deployment |
| 0 test cases | Deploy (no tests = no requirement) |
| No coverage report found | Deploy (assume tests pass) |

### Stage 8: Build

**Purpose**: Create production-ready artifacts

```bash
npm run build
```

**Output**:
```
dist/
├── index.html
├── assets/
│   ├── index.abc123.js
│   ├── index.def456.css
│   └── ...
└── ...
```

**Build Artifacts**: React app compiled and minified

### Stage 9: Deploy to Production

**Purpose**: Copy artifacts and restart service (main branch only)

```bash
# Only runs when:
# 1. Branch is "main"
# 2. Previous stages passed
# 3. Coverage threshold met

# Actions:
1. Backup current deployment
2. Copy dist/* to /opt/applications/oan-ui-service/dist/
3. Restart Nginx
4. Verify Nginx started
```

**Backup Location**:
```
/opt/applications/oan-ui-service/dist.backup.20240115_143022/
```

**When deployment skips**:
- Feature branch pushed (not main)
- Tests failed
- Coverage < 85%

### Stage 10: Health Check

**Purpose**: Verify application is running after deployment

```bash
curl http://localhost:5000/health
# Expected response: HTTP 200
```

**Retry Logic**:
- Attempts: 5 times
- Interval: 2 seconds between attempts
- Total timeout: ~10 seconds

**Exit conditions**:
- ✓ HTTP 200 received → SUCCESS
- ✗ Still failing after 5 attempts → FAILURE

### Stage 11: Generate Report

**Purpose**: Create deployment summary

```bash
cat >> /opt/deployment-info.txt << 'REPORT'
Jenkins Build #${BUILD_NUMBER}
Branch: ${GITHUB_BRANCH_ENV}
Timestamp: $(date)
Status: SUCCESS
Coverage: ${COVERAGE_PERCENT}%
Health Check: PASSED
REPORT
```

---

## Complete Workflow Examples

### Example 1: Push to Main Branch (Auto-Deploy)

**Trigger**: Developer pushes code to main branch

```bash
# Developer commits and pushes
git commit -m "Fix: Update speech API integration"
git push origin main
```

**Jenkins Pipeline**:

```
1. GitHub webhook notifies Jenkins (10 seconds)
2. Jenkins clones repository (20 seconds)
3. Verify environment (10 seconds)
4. Install dependencies (30 seconds)
5. Run tests & coverage (45 seconds)
   └─ Coverage: 92.1% ✓ (above 85% threshold)
6. Build artifacts (25 seconds)
7. Deploy to production (15 seconds)
8. Health check (5 seconds)
9. Report generated (2 seconds)

Total Time: ~2 minutes
Status: ✓ DEPLOYED
```

**Result**: 
- Application automatically updated on instance
- New build available immediately
- Health check verified deployment successful

### Example 2: Push to Feature Branch (Build Only)

**Trigger**: Developer pushes code to feature branch

```bash
# Developer works on feature
git checkout -b feature/add-language-support
git commit -m "Add Spanish language support"
git push origin feature/add-language-support
```

**Jenkins Pipeline**:

```
1. GitHub webhook notifies Jenkins (10 seconds)
2. Jenkins clones feature branch (20 seconds)
3. Verify environment (10 seconds)
4. Install dependencies (30 seconds)
5. Run tests & coverage (45 seconds)
   └─ Coverage: 78.2% ✗ (below 85% threshold)
6. Parse coverage (2 seconds)
7. Coverage threshold check FAILS
   └─ Error: Required 85%, got 78.2%

Build Status: ✗ FAILED
Deployment: BLOCKED
```

**Result**:
- Build fails, preventing deployment
- Developer reviews logs to improve test coverage
- Commits new tests
- Re-pushes to feature branch
- Pipeline runs again

### Example 3: Manual Deploy (Override Branch)

**Trigger**: Developer manually triggers build from Jenkins

1. Jenkins UI → oan-ui-service → **Build with Parameters**
2. **GITHUB_BRANCH**: `hotfix/urgent-fix`
3. Click **Build**

**Pipeline**:

```
1. Jenkins clones hotfix/urgent-fix (20 seconds)
2. Install dependencies (30 seconds)
3. Run tests & coverage (45 seconds)
4. Coverage: 85.0% ✓
5. Build artifacts (25 seconds)
6. Deploy stage SKIPPED
   └─ (Only main branch auto-deploys)
7. Report generated (2 seconds)

Build Status: ✓ SUCCESS
Deployment: MANUAL (requires separate approval)
```

**Result**:
- Build succeeds
- Artifacts ready for manual deployment
- Administrator reviews, then manually deploys

---

## Code Coverage Deep Dive

### Understanding Coverage Metrics

**Example Coverage Report**:
```
=============================== Coverage Summary ===============================
Statements   : 92.3% ( 1234/1337 )
Branches     : 88.5% ( 189/213 )
Functions    : 91.2% ( 234/256 )
Lines        : 93.1% ( 1189/1276 )
================================================================================

Uncovered Lines:
  src/api/speechApi.ts:45-52 (error handling)
  src/components/AudioPlayer.tsx:78-85 (pause logic)
  src/utils/audioProcessor.ts:120-128 (edge case)
```

### Coverage Threshold Logic

```groovy
COVERAGE_THRESHOLD = 85

IF COVERAGE >= 85:
    echo "✓ PASS: Coverage ${COVERAGE}% >= ${COVERAGE_THRESHOLD}%"
    DEPLOY = true
    
ELIF COVERAGE < 85 AND TESTS_COUNT > 0:
    echo "✗ FAIL: Coverage ${COVERAGE}% < ${COVERAGE_THRESHOLD}%"
    DEPLOY = false
    BUILD_STATUS = FAILURE
    
ELIF TESTS_COUNT == 0:
    echo "⚠ SKIP: No tests found"
    DEPLOY = true  // Allow deployment anyway
```

### Improving Coverage

If coverage < 85%, developers should:

```bash
# 1. Check which lines are uncovered
npm test -- --coverage

# 2. Review coverage report
open coverage/lcov-report/index.html

# 3. Add tests for uncovered lines
# Example uncovered: Error handling in API call

// Before: Function not fully tested
const result = await fetchSpeech();

// After: Test error case
test('should handle API errors gracefully', async () => {
    mockFetchSpeech.mockRejectedValue(new Error('Network error'));
    const result = await fetchSpeech();
    expect(result).toEqual(null);
});

# 4. Verify coverage improved
npm test -- --coverage
# If >= 85%, commit and re-push
```

---

## Post-Deployment Verification

After successful deployment, verify:

### 1. Health Check Endpoint

```bash
curl -v http://<INSTANCE_IP>:5000/health
# Expected: HTTP 200 OK
```

### 2. Application Accessibility

```bash
# Via Load Balancer
curl -v http://<LOAD_BALANCER_IP>/

# Via Instance Direct
curl -v http://<INSTANCE_IP>:5000/

# Expected: HTTP 200 with HTML content
```

### 3. API Endpoints

```bash
# TTS Endpoint (requires JWT token)
curl -X POST http://localhost:5000/api/tts/ \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello"}'

# Transcription Endpoint
curl -X POST http://localhost:5000/api/transcribe/ \
  -F "audio=@audio.wav" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

### 4. Logs and Reports

```bash
# Deployment report
cat /opt/deployment-info.txt

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Build logs
cat /var/log/oan-ui-service-build.log

# Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

---

## Troubleshooting Pipeline

### Build Failed: Coverage Below Threshold

**Error**:
```
✗ COVERAGE BELOW THRESHOLD
Required: 85% | Actual: 78.2%
Build will FAIL - deployment blocked
```

**Solution**:
1. Check which lines are uncovered
   ```bash
   npm test -- --coverage
   open coverage/lcov-report/index.html
   ```

2. Add tests for uncovered code
3. Commit tests
4. Push to branch
5. Pipeline runs again with improved coverage

### Build Failed: Health Check

**Error**:
```
Health check failed after 5 attempts
curl: (7) Failed to connect to localhost port 5000
```

**Solutions**:
1. Verify Nginx is running
   ```bash
   sudo systemctl status nginx
   ```

2. Check Nginx error logs
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. Verify port 5000 is listening
   ```bash
   sudo netstat -tlnp | grep 5000
   ```

4. Check application permission to /opt/applications/
   ```bash
   ls -la /opt/applications/oan-ui-service/
   ```

### Build Failed: Dependency Installation

**Error**:
```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

**Solution**:
1. Update package-lock.json
   ```bash
   npm install
   npm ci
   git add package-lock.json
   git commit -m "Update dependencies"
   git push origin main
   ```

2. Or use npm legacy peer deps
   ```bash
   npm ci --legacy-peer-deps
   ```

---

## Performance Optimization

### Reducing Build Time

**Current**: ~2 minutes per build

**Optimization**:
```groovy
// 1. Cache npm packages
options {
    timestamps()
    disableConcurrentBuilds()
}

// 2. Parallel test execution
stage('Tests') {
    parallel {
        stage('Unit Tests') { steps { sh 'npm test -- --testPathPattern=unit' } }
        stage('Integration') { steps { sh 'npm test -- --testPathPattern=integration' } }
    }
}

// 3. Skip tests on non-main branches
when {
    branch 'main'
}
```

### Docker Layer Caching

Use Docker to cache dependencies:

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --legacy-peer-deps

COPY . .
RUN npm run build

CMD ["npm", "start"]
```

---

## Security Considerations

### 1. Secrets Management

Don't hardcode secrets in Jenkinsfile:

```groovy
// ❌ WRONG
environment {
    API_KEY = "sk_live_abc123def456"
}

// ✓ CORRECT
withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
    sh 'curl -H "Authorization: $API_KEY" https://api.example.com'
}
```

### 2. Artifact Cleanup

Clean old build artifacts:

```bash
# Jenkins automatically keeps last 10 builds
# Older builds are deleted
# Configure: Jenkins UI → Job → Configure → Build Discarder
```

### 3. Log Sanitization

Mask sensitive information in logs:

```groovy
withCredentials([file(credentialsId: 'deployment-key', variable: 'KEYFILE')]) {
    sh '''
        # Don't echo the key file contents
        chmod 600 $KEYFILE
        ssh-keygen -y -f $KEYFILE > pub.key  # Public key only
    '''
}
```

---

## Monitoring and Alerting

### Jenkins Pipeline Notifications

**Email on Failure**:
```groovy
post {
    failure {
        emailext(
            subject: "Build Failed: ${BUILD_NUMBER}",
            body: "${BUILD_LOG_EXCERPT}",
            to: "dev-team@example.com"
        )
    }
}
```

**Slack Notifications**:
```groovy
post {
    always {
        slackSend(
            channel: '#jenkins-builds',
            color: currentBuild.result == 'SUCCESS' ? 'good' : 'danger',
            message: "${BUILD_URL}"
        )
    }
}
```

### Build Metrics

Monitor build trends:
- Build duration (should stay < 3 minutes)
- Build success rate (should be > 95%)
- Test coverage trends (should be ≥ 85%)

---

## Quick Reference

### Common Commands

```bash
# View latest build
curl http://jenkins:8080/job/oan-ui-service/lastBuild/api/json

# Trigger build via CLI
curl -X POST http://jenkins:8080/job/oan-ui-service/build

# Trigger with parameters
curl -X POST "http://jenkins:8080/job/oan-ui-service/buildWithParameters?GITHUB_BRANCH=hotfix/bug-fix"

# Get build artifacts
curl http://jenkins:8080/job/oan-ui-service/lastBuild/artifact
```

### Key Files

| File | Purpose |
|------|---------|
| `/opt/applications/oan-ui-service/Jenkinsfile` | Pipeline definition |
| `/var/lib/jenkins/jobs/oan-ui-service/` | Job configuration |
| `/var/log/oan-ui-service-build.log` | Build output |
| `/opt/deployment-info.txt` | Deployment reports |
| `/var/log/nginx/access.log` | Request logs |

---

## Next Steps

1. ✓ Understand pipeline stages
2. ✓ Know coverage threshold rules
3. → Create GitHub webhook
4. → Push test code to main branch
5. → Monitor first build in Jenkins
6. → Review deployment logs
7. → Verify health check

---

**Version**: 1.0  
**Last Updated**: 2024-01-15  
**Related**: [Jenkins Setup](./JENKINS_SETUP_GUIDE.md) | [GitHub Webhooks](./GITHUB_WEBHOOK_SETUP.md)
