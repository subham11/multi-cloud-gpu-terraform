# GitHub Webhook Configuration Guide

Complete step-by-step guide for configuring GitHub webhooks to trigger Jenkins CI/CD pipelines automatically.

## Overview

GitHub webhooks allow your repositories to notify Jenkins whenever:
- Code is pushed to a branch
- A pull request is opened/updated
- Commits are made

This enables **automatic CI/CD pipeline triggers** without manual intervention.

---

## Prerequisites

Before configuring webhooks, ensure:

1. ✓ Jenkins is installed and running on port 8080
2. ✓ Jenkins is accessible from the internet (or GitHub can reach it)
3. ✓ GitHub credentials are configured in Jenkins
4. ✓ Pipeline jobs are created in Jenkins
5. ✓ You have admin access to the GitHub repository

---

## Step 1: Determine Jenkins Access URL

Jenkins must be accessible from GitHub's servers.

### Option A: Load Balancer IP (Recommended)

```
http://<LOAD_BALANCER_IP>:8080
```

Get load balancer IP:
```bash
# For AWS
aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName'

# For Azure
az network public-ip show -g <resource-group> -n <pip-name> --query ipAddress

# For GCP
gcloud compute addresses list --format="value(ADDRESS)"
```

### Option B: Instance Public IP

```
http://<INSTANCE_PUBLIC_IP>:8080
```

### Option C: Custom Domain (If Configured)

```
http://jenkins.yourdomain.com:8080
```

### Test Accessibility

```bash
curl -v http://<JENKINS_URL>:8080
# Should return HTTP 200
```

---

## Step 2: Configure OAN UI Service Webhook

### 2.1 Access Repository Webhook Settings

1. Go to: https://github.com/the-swag-coder/oan-ui-service
2. Click **Settings** (top right)
3. Left sidebar → **Webhooks**
4. Click **Add webhook** button

### 2.2 Enter Webhook Details

Fill in the following fields:

**Payload URL**
```
http://<JENKINS_URL>:8080/github-webhook/
```

**Content type**
```
Select: application/json
```

**Events - Which events would you like to trigger this webhook?**
```
Select: Let me select individual events
Then check:
  ✓ Push events
  ✓ Pull requests
  ✓ Branch or tag creation
```

Alternatively, select:
```
Select: Just the push event (simpler, recommended for basic setup)
```

**Active**
```
✓ Checked (enabled)
```

### 2.3 Save Webhook

Click **Add webhook** button

**Success**: Page shows webhook with checkmark and HTTP response 200

---

## Step 3: Configure Agri Help Webhook (When Available)

Repeat Step 2 for Agri Help repository:

1. Go to: https://github.com/Sulopatech/agri_help
2. Follow the same webhook configuration steps
3. Use the same Jenkins URL and endpoint

---

## Step 4: Test Webhooks

### 4.1 GitHub Webhook Delivery History

1. GitHub → Repository → Settings → Webhooks
2. Click on the webhook URL
3. Scroll to **Recent Deliveries** section
4. Click on the latest delivery entry

**Should show**:
```
Request
  POST /github-webhook/ HTTP/1.1
  Host: <JENKINS_URL>:8080
  Content-Type: application/json
  Content-Length: XXXX

Response
  HTTP/1.1 200 OK
```

### 4.2 Manual Webhook Test

If no deliveries appear, test manually:

```bash
curl -X POST http://<JENKINS_URL>:8080/github-webhook/ \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{
    "action": "opened",
    "repository": {
      "name": "oan-ui-service",
      "full_name": "the-swag-coder/oan-ui-service",
      "html_url": "https://github.com/the-swag-coder/oan-ui-service"
    }
  }'

# Should return HTTP 200 and Jenkins should respond
```

### 4.3 Trigger with Real Code Push

The ultimate test - trigger webhook with actual code change:

```bash
# Clone repository (if not already cloned)
git clone https://github.com/the-swag-coder/oan-ui-service.git
cd oan-ui-service

# Create a test commit
git commit --allow-empty -m "Trigger Jenkins webhook"

# Push to main branch
git push origin main

# Jenkins should automatically start a build within 10 seconds
```

**Verify in Jenkins**:
1. Go to Jenkins UI → oan-ui-service
2. Check if new build appeared in build history
3. Click build to view console output
4. Verify pipeline executed all stages

---

## Step 5: Monitor Webhook Activity

### 5.1 View Recent Deliveries

1. GitHub → Repository → Settings → Webhooks
2. Click webhook URL
3. Scroll to **Recent Deliveries**
4. Each delivery shows:
   - Event type (push, pull request, etc.)
   - Status (green = success, red = failure)
   - Response time
   - Request/response details

### 5.2 Check Jenkins Activity

**Via Jenkins UI**:
1. Dashboard → oan-ui-service
2. View "Build History" on left
3. New builds should appear when webhook triggers

**Via Jenkins Logs**:
```bash
# Watch Jenkins log in real-time
sudo tail -f /var/log/jenkins/jenkins.log | grep -i webhook

# Look for messages like:
# "GitHub hook triggered"
# "Starting build"
```

### 5.3 GitHub Event Logs

```bash
# If you have GitHub CLI installed
gh repo view the-swag-coder/oan-ui-service \
  --web  # Opens repo in browser

# Check activity feed in repository
```

---

## Webhook Configuration Scenarios

### Scenario 1: Main Branch Auto-Deploy

**Goal**: Automatically deploy when code is merged to main

**GitHub Webhook Settings**:
- Events: Push events
- Branches: Only main

**Jenkins Pipeline**:
```groovy
triggers {
    githubPush()
}

stages {
    stage('Deploy') {
        when {
            branch 'main'
        }
        steps { /* deploy logic */ }
    }
}
```

### Scenario 2: All Branches Auto-Build

**Goal**: Build and test all branches, only deploy main

**GitHub Webhook Settings**:
- Events: Push events
- Branches: All branches

**Jenkins Pipeline**:
```groovy
triggers {
    githubPush()
}

stages {
    stage('Deploy') {
        when {
            branch 'main'
        }
        steps { /* deploy only main */ }
    }
}
```

### Scenario 3: Pull Request Checks

**Goal**: Run tests on pull requests before merge

**GitHub Webhook Settings**:
- Events: 
  - ✓ Push events
  - ✓ Pull requests

**Jenkins Pipeline**:
```groovy
triggers {
    githubPush()
}

// Add branch conditions as needed
```

---

## Troubleshooting Webhook Issues

### Issue: Webhook showing red X (failed delivery)

**Possible Causes**:

1. **Jenkins is not accessible**
   - Verify Jenkins URL is correct and accessible
   - Check firewall allows port 8080 from GitHub
   - Test: `curl -v http://<JENKINS_URL>:8080`

2. **Jenkins GitHub plugin not installed**
   - Jenkins UI → Manage Jenkins → Plugin Manager
   - Search for "GitHub"
   - Install "GitHub plugin" and "GitHub Integration plugin"

3. **Webhook URL is wrong**
   - Should end with: `/github-webhook/`
   - Common mistake: Missing trailing slash
   - Correct: `http://jenkins.example.com:8080/github-webhook/`
   - Wrong: `http://jenkins.example.com:8080/github-webhook`

**Solution**:
```bash
# Verify webhook endpoint
curl -v http://<JENKINS_URL>:8080/github-webhook/

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins if needed
sudo systemctl restart jenkins
```

### Issue: Webhook not triggering builds

**Possible Causes**:

1. **Jenkins job not configured for GitHub trigger**
   - Jenkins UI → Job → Configure
   - Check: "GitHub hook trigger for GITScm polling" is enabled

2. **Webhook event types not matching**
   - Make sure "Push events" is selected in GitHub

3. **Jenkins credentials invalid**
   - Jenkins UI → Manage Jenkins → Configure System
   - Test GitHub connection
   - Verify credentials are correct

**Solution**:
```bash
# Enable GitHub hook trigger in Jenkinsfile
triggers {
    githubPush()
}

# Or in classic Jenkins UI:
# Configure Job → Build Triggers → GitHub hook trigger for GITScm polling
```

### Issue: Build triggers but fails immediately

**Possible Causes**:

1. **Repository URL mismatch**
   - Ensure Jenkins job URL matches webhook repo exactly

2. **Branch doesn't exist**
   - Jenkins looking for branch that doesn't exist
   - Verify branch name (case-sensitive)

3. **Credentials needed for private repo**
   - Add GitHub credentials to Jenkins
   - Update job configuration with credentials

**Solution**:
```bash
# Check Jenkins job configuration
# Jenkins UI → oan-ui-service → Configure
# Verify:
# - Repository URL: https://github.com/the-swag-coder/oan-ui-service.git
# - Branch: */main
# - Credentials: (if private repo)
```

### Issue: Permission denied when webhook tries to access repo

**Solution**:
1. Create GitHub Personal Access Token (if private repo)
2. Add to Jenkins credentials
3. Select credentials in job configuration
4. Rebuild webhook test

```bash
# GitHub → Settings → Developer settings → Personal access tokens
# Create token with: repo, admin:repo_hook scopes
# Copy token
# Jenkins UI → Manage Credentials → Add Credentials
# Select: Username with password
# Username: <github-username>
# Password: <paste-token>
# ID: github-credentials
```

---

## Advanced Webhook Configuration

### Custom Webhook Payload

Transform webhook data before Jenkins processes:

1. GitHub → Webhooks → Click webhook → Edit
2. **Payload URL** examples:
   - `http://jenkins:8080/github-webhook/` (standard)
   - `http://jenkins:8080/job/oan-ui-service/build?token=<BUILD_TOKEN>` (direct job trigger)

### Webhook Filtering by Branch

Only trigger on specific branches:

**Method 1: GitHub Branch Protection Rules**
1. Settings → Branches → Add rule
2. Pattern: `main`
3. Require status checks to pass

**Method 2: Jenkins Jenkinsfile**
```groovy
triggers {
    githubPush()
}

pipeline {
    stages {
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps { sh 'echo "Deploying main branch"' }
        }
        stage('Test Other') {
            when {
                not { branch 'main' }
            }
            steps { sh 'echo "Testing feature branch"' }
        }
    }
}
```

### Webhook Secret Token (Optional Security)

Add HMAC secret to verify webhook authenticity:

1. GitHub → Webhooks → Click webhook
2. **Secret** field: Enter a random secret string
3. Jenkins GitHub plugin validates HMAC signature

**Jenkins Configuration**:
```groovy
// Jenkins automatically validates if secret is configured
// No additional setup needed
```

---

## Webhook Best Practices

### 1. Monitor Webhook Health

- Check "Recent Deliveries" monthly
- Watch for error patterns
- Alert if delivery rate drops

### 2. Use Meaningful Commit Messages

```bash
git commit -m "Fix: Update npm dependencies"
# Jenkins logs will show this message
```

### 3. Tag Releases with Webhooks

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Configure webhook for tag events if needed
```

### 4. Webhook Timeout Considerations

- GitHub waits max 30 seconds for webhook response
- If Jenkins is slow, webhook may timeout
- Increase Jenkins memory if builds take >30s

### 5. Backup Webhook Configuration

```bash
# Export webhook settings
gh api repos/the-swag-coder/oan-ui-service/hooks \
  --paginate > webhook-backup.json
```

---

## Quick Reference

### Common Webhook URLs

| Setup | URL |
|-------|-----|
| Load Balancer | `http://<LB-IP>:8080/github-webhook/` |
| Direct Instance | `http://<INSTANCE-IP>:8080/github-webhook/` |
| Domain Name | `http://jenkins.yourdomain.com:8080/github-webhook/` |
| Behind Reverse Proxy | `http://yourdomain.com/jenkins/github-webhook/` |

### Jenkins Webhook Endpoints

| Plugin | Endpoint |
|--------|----------|
| GitHub Plugin | `/github-webhook/` |
| GitLab Plugin | `/gitlab/push` |
| Bitbucket Plugin | `/bitbucket-hook/` |
| Gitea Plugin | `/gitea-webhook/` |

### Event Types Reference

| Event | Triggers When |
|-------|---|
| Push | Code pushed to branch |
| Pull Request | PR opened, updated, or synced |
| Branch/Tag Creation | New branch or tag created |
| Releases | Release published |
| Issues | Issue opened, edited, etc. |
| Issue Comments | Comment added to issue |

---

## Testing Webhook End-to-End

Complete test checklist:

```bash
# 1. Verify Jenkins is running
curl http://<JENKINS_URL>:8080
# Expected: HTTP 200

# 2. Verify GitHub webhook exists
# Expected: Green checkmark next to webhook URL

# 3. Make a test commit
cd <local-repo>
git commit --allow-empty -m "Test webhook trigger"
git push origin main

# 4. Check Jenkins build started
curl http://<JENKINS_URL>:8080/api/json | grep lastBuild
# Expected: New build number appeared

# 5. Verify webhook delivery succeeded
# GitHub → Settings → Webhooks → Recent Deliveries
# Expected: Latest delivery shows HTTP 200 response

# 6. Check build completed
# Jenkins UI → Job → Build History
# Expected: Build #N shows SUCCESS
```

---

## Documentation Links

- **GitHub Webhooks**: https://docs.github.com/en/developers/webhooks-and-events/webhooks
- **GitHub CLI Webhook Management**: https://cli.github.com/manual/gh_api
- **Jenkins GitHub Plugin**: https://plugins.jenkins.io/github/
- **Jenkins Webhook Documentation**: https://www.jenkins.io/doc/book/system-administration/webhooks/

---

**Version**: 1.0  
**Last Updated**: 2024-01-15  
**Related**: [Jenkins Setup Guide](./JENKINS_SETUP_GUIDE.md)
