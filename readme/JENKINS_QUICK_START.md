# Jenkins CI/CD Quick Start Guide

Fast-track guide to deploy, configure, and test Jenkins CI/CD pipelines.

## ⏱️ Quick Timeline

| Step | Time | Task |
|------|------|------|
| 1 | 5 min | Deploy instance with Terraform |
| 2 | 35-50 min | Wait for cloud-init (NVIDIA + Jenkins) |
| 3 | 5 min | Access Jenkins and complete wizard |
| 4 | 5 min | Configure GitHub credentials |
| 5 | 5 min | Create pipeline job |
| 6 | 5 min | Configure GitHub webhook |
| 7 | 2 min | Test with code push |
| **Total** | **60-90 min** | **Complete CI/CD Setup** |

---

## 1. Deploy Instance (5 minutes)

### Deploy to AWS (Recommended)

```bash
cd /Volumes/SatyBkup/projects/multi-cloud-gpu-terraform

# Deploy to Mumbai region
terraform apply -var="cloud_provider=aws" -var="aws_region=ap-south-1"

# Note: Save the outputs (Load Balancer IP, Instance IP)
```

### Deploy to Azure or GCP

```bash
# Azure
terraform apply -var="cloud_provider=azure" -var="azure_region=southeastasia"

# GCP
terraform apply -var="cloud_provider=gcp" -var="gcp_region=asia-south1"
```

**Save these outputs**:
- Load Balancer IP
- Instance Public IP
- Instance SSH Key (if needed)

---

## 2. Wait for Cloud-Init (35-50 minutes)

Monitor instance boot:

```bash
# SSH into instance
ssh -i <key-file> ubuntu@<INSTANCE_IP>

# Watch cloud-init progress
tail -f /var/log/cloud-init-output.log

# Look for these messages:
# ✓ "Starting NVIDIA driver installation"
# ✓ "NVIDIA drivers installed successfully"
# ✓ "Starting Node.js installation"
# ✓ "Starting Jenkins CI/CD setup"
# ✓ "Jenkins CI/CD setup completed"
```

**What's being installed** (in order):
1. NVIDIA drivers + CUDA (10-15 min)
2. Node.js v18 (2-3 min)
3. OAN UI Service + Nginx (5-10 min)
4. **NEW** Jenkins + Java (5-10 min)

---

## 3. Access Jenkins (5 minutes)

### Get Initial Password

```bash
# On the instance or via SSH
cat /opt/jenkins-initial-password.txt

# Copy the password (you'll need it in a moment)
```

### Open Jenkins UI

**Via Load Balancer (Recommended)**:
```
http://<LOAD_BALANCER_IP>:8080
```

**Via Instance Direct**:
```
http://<INSTANCE_IP>:8080
```

### Complete Setup Wizard

1. **Unlock Jenkins**
   - Paste the password from step above
   - Click "Continue"

2. **Install Plugins**
   - Click "Install suggested plugins"
   - Wait 5-10 minutes for installation

3. **Create Admin User**
   - Username: `admin`
   - Password: Enter a strong password
   - Full name: Your name
   - Email: Your email

4. **Configure Jenkins URL**
   - Jenkins URL: `http://<LOAD_BALANCER_IP>:8080/`
   - Click "Save and Finish"

Jenkins is now ready!

---

## 4. Configure GitHub Credentials (5 minutes)

### Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. **Token name**: `jenkins-ci-token`
4. **Scopes** (select):
   - ✓ repo
   - ✓ admin:repo_hook
5. Click "Generate token"
6. **Save the token** (copy it now!)

### Add to Jenkins

1. Jenkins UI → **Manage Jenkins**
2. Left sidebar → **Manage Credentials**
3. Click **System**
4. Click **Global credentials (unrestricted)**
5. Click **Add Credentials**
6. Fill in:
   - **Kind**: Username with password
   - **Username**: Your GitHub username
   - **Password**: Paste the token (NOT your password)
   - **ID**: `github-credentials`
   - **Description**: `GitHub CI/CD Token`
7. Click **Create**

---

## 5. Create Pipeline Job (5 minutes)

### Create OAN UI Service Pipeline

1. Jenkins UI → **New Item**
2. **Item name**: `oan-ui-service`
3. **Type**: Pipeline
4. Click **OK**

### Configuration

1. **GitHub Project**: https://github.com/the-swag-coder/oan-ui-service
2. **Build Triggers**:
   - ✓ Check "GitHub hook trigger for GITScm polling"
3. **Pipeline**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: https://github.com/the-swag-coder/oan-ui-service.git
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`

4. Click **Save**

---

## 6. Configure GitHub Webhook (5 minutes)

### Add Webhook to Repository

1. GitHub → https://github.com/the-swag-coder/oan-ui-service
2. Settings → **Webhooks**
3. Click **Add webhook**
4. Fill in:
   - **Payload URL**: `http://<JENKINS_URL>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select "Just the push event"
   - **Active**: ✓ Checked
5. Click **Add webhook**

**Success**: Page shows webhook with checkmark ✓

---

## 7. Test Pipeline (2 minutes)

### Trigger with Code Push

```bash
# Clone the OAN UI Service repository
git clone https://github.com/the-swag-coder/oan-ui-service.git
cd oan-ui-service

# Create test commit
git commit --allow-empty -m "Trigger Jenkins pipeline"

# Push to main branch
git push origin main
```

### Monitor in Jenkins

1. Jenkins UI → **oan-ui-service**
2. **Build History** should show new build
3. Click on build to see console output

**Expected output**:
```
[Pipeline] stage('Initialization')
[Pipeline] stage('Checkout')
[Pipeline] stage('Verify Node.js')
[Pipeline] stage('Install Dependencies')
[Pipeline] stage('Run Tests & Coverage')
[Pipeline] stage('Build')
[Pipeline] stage('Deploy to Production')
[Pipeline] stage('Health Check')
✓ Build SUCCESS
```

---

## Verification Checklist

After setup, verify everything works:

- [ ] Jenkins accessible at `http://<LOAD_BALANCER>:8080`
- [ ] Admin user can log in
- [ ] Pipeline job "oan-ui-service" exists
- [ ] GitHub webhook shows recent delivery
- [ ] Webhook delivery shows HTTP 200 response
- [ ] Code push triggers automatic build
- [ ] Build completes in ~2 minutes
- [ ] Application deployed to `http://<LOAD_BALANCER>`
- [ ] Health check endpoint responds: `curl http://localhost:5000/health`
- [ ] Deployment report updated: `cat /opt/deployment-info.txt`

---

## Common Issues & Quick Fixes

### Issue: "Can't access Jenkins at port 8080"

```bash
# Check if Jenkins is running
sudo systemctl status jenkins

# Check if port is listening
sudo netstat -tlnp | grep 8080

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

### Issue: "Initial password file not found"

```bash
# Get password directly from Jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Issue: "Webhook not triggering builds"

```bash
# Verify webhook URL is correct
curl -v http://<JENKINS>:8080/github-webhook/

# Check GitHub webhook recent deliveries
# GitHub → Repo → Settings → Webhooks → Click webhook
```

### Issue: "Build fails with coverage error"

```bash
# This means: Coverage < 85%
# Solution: Add more tests to increase coverage

# Check current coverage
npm test -- --coverage

# View coverage report
open coverage/lcov-report/index.html

# Add tests for uncovered lines
# Commit and push again
```

---

## Next Steps

### For Development

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   git push origin feature/my-feature
   ```

2. **Push code to feature branch**:
   - Webhook triggers build automatically
   - Build runs tests and checks coverage
   - If coverage >= 85%, build passes
   - If coverage < 85%, build fails
   - Add more tests and re-push

3. **Create pull request**:
   - Jenkins shows build status on PR

4. **Merge to main**:
   - Webhook triggers automatic deployment
   - Build runs
   - Application auto-deployed if tests pass

### For Production Monitoring

1. **Monitor builds**: Jenkins UI → Dashboard
2. **Check health**: `curl http://<LOAD_BALANCER>/health`
3. **View logs**: `sudo tail -f /var/log/nginx/access.log`
4. **Track deployments**: `cat /opt/deployment-info.txt`

---

## Key URLs & Commands

### URLs

```
Jenkins:            http://<LOAD_BALANCER>:8080
Application:        http://<LOAD_BALANCER>
Health Check:       http://<LOAD_BALANCER>:5000/health
Pipeline Job:       http://<LOAD_BALANCER>:8080/job/oan-ui-service
GitHub Webhook:     http://<LOAD_BALANCER>:8080/github-webhook/
```

### Commands

```bash
# Get Jenkins password
cat /opt/jenkins-initial-password.txt

# Check deployment status
cat /opt/deployment-info.txt

# Verify application
curl -v http://localhost:5000/health

# Monitor Jenkins
sudo tail -f /var/log/jenkins/jenkins.log

# Monitor build
tail -f /var/log/oan-ui-service-build.log

# Check Nginx
sudo systemctl status nginx
```

---

## Documentation References

For more detailed information, see:

- [Jenkins Setup Guide](./JENKINS_SETUP_GUIDE.md) - Complete installation & configuration
- [GitHub Webhook Setup](./GITHUB_WEBHOOK_SETUP.md) - Webhook step-by-step
- [CI/CD Pipeline Workflow](./CI-CD_PIPELINE_WORKFLOW.md) - Pipeline stages & logic
- [App Deployment Guide](./APP_DEPLOYMENT_GUIDE.md) - Application deployment details

---

## Support

If you encounter issues:

1. Check the **Common Issues** section above
2. Review relevant documentation guide
3. Check logs:
   ```bash
   sudo tail -f /var/log/cloud-init-output.log
   sudo tail -f /var/log/jenkins/jenkins.log
   sudo tail -f /var/log/nginx/error.log
   ```

---

## Summary

✓ Jenkins installed and configured  
✓ GitHub integration ready  
✓ Pipeline job created  
✓ Webhook configured  
✓ First build tested  

**You're ready to use CI/CD!**

Start with: `git push origin main` to trigger automatic deployment

---

**Version**: 1.0  
**Status**: Ready to Use  
**Last Updated**: 2024-01-15
