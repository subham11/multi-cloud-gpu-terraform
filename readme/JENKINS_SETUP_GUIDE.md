# Jenkins CI/CD Setup & Configuration Guide

## Overview

This guide covers the complete setup and configuration of Jenkins for automated CI/CD pipelines in the multi-cloud GPU Terraform project.

### Features

- **Automatic Triggers**: GitHub webhooks on main branch push/merge events
- **Manual Deployment**: Parameterized builds for deploying specific branches
- **Test Enforcement**: Automatic unit test execution before deployment
- **Coverage Threshold**: 85% code coverage requirement for deployment
- **Health Checks**: Post-deployment verification
- **Build Reports**: Automated report generation

---

## 1. Installation

### Automatic Installation (via Cloud-Init)

Jenkins is automatically installed on instance startup via cloud-init:

1. Java (OpenJDK 11+) is installed
2. Jenkins repository is added to package manager
3. Jenkins service is installed and started
4. Initial admin password is saved to `/opt/jenkins-initial-password.txt`
5. Nginx reverse proxy is configured for Jenkins on port 8080

### Manual Installation

If Jenkins needs to be installed manually:

```bash
# Install Java
sudo apt-get update
sudo apt-get install -y default-jre default-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | \
  gpg --dearmor -o /usr/share/keyrings/jenkins-archive-keyring.gpg
echo deb [signed-by=/usr/share/keyrings/jenkins-archive-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/ | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install and start Jenkins
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 2. Initial Jenkins Setup

### Access Jenkins

**Via Load Balancer:**
```
http://<LOAD_BALANCER_IP>:8080
```

**Via Instance Direct:**
```
http://<INSTANCE_IP>:8080
```

### Setup Wizard

1. **Unlock Jenkins**
   - Get password: `cat /opt/jenkins-initial-password.txt`
   - Paste into Jenkins UI
   - Click "Continue"

2. **Install Suggested Plugins**
   - Select "Install suggested plugins"
   - Wait for installation (5-10 minutes)

3. **Create Admin User**
   - Username: `admin` (or preferred)
   - Password: Set secure password
   - Full name: `CI/CD Administrator`
   - Email: Your email address
   - Click "Save and Continue"

4. **Configure Jenkins URL**
   - Jenkins URL: `http://<LOAD_BALANCER_IP>:8080/` (or instance IP)
   - Click "Save and Finish"

### Required Plugins

Install these plugins for full CI/CD functionality:

**Via Jenkins UI (Manage Jenkins → Plugin Manager → Available):**

```
✓ GitHub plugin (github)
✓ GitHub Integration plugin (github-api)
✓ Blue Ocean plugin (blueocean)
✓ JUnit plugin (junit)
✓ Cobertura plugin (cobertura) - For coverage reports
✓ Code Coverage API (code-coverage-api)
✓ Credentials Binding plugin (credentials-binding)
```

**OR via Jenkins CLI:**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
  github github-api blueocean junit cobertura code-coverage-api \
  credentials-binding
```

---

## 3. GitHub Integration

### Step 1: Create GitHub Personal Access Token

1. Log in to GitHub → Settings → Developer settings → Personal access tokens
2. Click "Generate new token"
3. **Token name**: `jenkins-ci-token`
4. **Scopes** (select):
   - `repo` (full control of private repositories)
   - `admin:repo_hook` (write access to hooks)
   - `admin:org_hook` (if using organization repos)
5. Click "Generate token"
6. **Save the token** (you won't see it again)

### Step 2: Add GitHub Credentials to Jenkins

1. Jenkins UI → Manage Jenkins → Manage Credentials
2. Click "System" on the left
3. Click "Global credentials (unrestricted)"
4. Click "Add Credentials"
5. **Kind**: Username with password
6. **Username**: Your GitHub username
7. **Password**: Paste the personal access token (not your GitHub password)
8. **ID**: `github-credentials`
9. **Description**: `GitHub CI/CD Token`
10. Click "Create"

### Step 3: Configure GitHub Server

1. Jenkins UI → Manage Jenkins → Configure System
2. Scroll to **GitHub** section
3. Click "Add GitHub Server" → "GitHub Server"
4. **API URL**: `https://api.github.com` (for public GitHub)
5. **Credentials**: Select `github-credentials` from dropdown
6. Click "Test connection"
7. Should show: `Credentials verified for user: <your-username>`
8. Click "Save"

---

## 4. Pipeline Job Creation

### OAN UI Service Pipeline

#### Option A: Create Pipeline from GitHub

1. Jenkins UI → New Item
2. **Item name**: `oan-ui-service`
3. **Type**: Pipeline
4. Click "OK"
5. **Configuration**:
   - **GitHub Project**: https://github.com/the-swag-coder/oan-ui-service
   - **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
   - **Pipeline**:
     - **Definition**: Pipeline script from SCM
     - **SCM**: Git
     - **Repository URL**: https://github.com/the-swag-coder/oan-ui-service.git
     - **Branch Specifier**: `*/main` (for automatic triggers)
     - **Script Path**: `Jenkinsfile`
6. Click "Save"

#### Option B: Upload Jenkinsfile to Repository

1. Copy the provided Jenkinsfile to your repository:
   ```bash
   cp ci-cd/oan-ui-service-jenkinsfile /path/to/oan-ui-service/Jenkinsfile
   git add Jenkinsfile
   git commit -m "Add CI/CD pipeline"
   git push origin main
   ```

2. Jenkins will automatically detect and use the Jenkinsfile

### Agri Help Pipeline (Template)

Once the Agri Help repository is available:

1. Follow the same steps as OAN UI Service
2. **Item name**: `agri_help`
3. **Repository**: https://github.com/Sulopatech/agri_help.git
4. **Script Path**: `Jenkinsfile`
5. Update the Jenkinsfile template with actual build commands

---

## 5. GitHub Webhook Configuration

### Step 1: Configure Webhook in Repository

1. GitHub → Repository → Settings → Webhooks
2. Click "Add webhook"
3. **Payload URL**: 
   ```
   http://<JENKINS_URL>:8080/github-webhook/
   ```
   Replace `<JENKINS_URL>` with:
   - Load Balancer IP (recommended)
   - Instance public IP
   - Domain name (if configured)

4. **Content type**: `application/json`
5. **Events** (select):
   - ✓ Push events
   - ✓ Pull requests
   - ✓ Pushes to branches
6. **Active**: Checked
7. Click "Add webhook"

### Step 2: Test Webhook

1. GitHub Webhooks page → Recent Deliveries
2. Click latest delivery
3. **Response** should show:
   ```
   HTTP/1.1 200 OK
   ```

### Step 3: Verify Trigger

1. Make a commit to main branch:
   ```bash
   git commit --allow-empty -m "Trigger Jenkins pipeline"
   git push origin main
   ```

2. Jenkins should automatically start a build
3. Check Jenkins UI → oan-ui-service → Build history

---

## 6. Pipeline Execution

### Automatic Trigger

**Trigger Event**: Push to main branch

```bash
# This will automatically trigger a Jenkins build
git commit -m "Update code"
git push origin main
```

**Jenkins will**:
1. Receive GitHub webhook notification
2. Clone the repository
3. Run tests with coverage
4. Check coverage threshold (85%)
5. Deploy if coverage >= 85%
6. Health check post-deployment

### Manual Trigger

1. Jenkins UI → oan-ui-service
2. Click "Build with Parameters"
3. **GITHUB_BRANCH**: Enter branch name (default: `main`)
4. Click "Build"

**Deployment Logic**:
- ✓ Main branch: Auto-deploy if tests pass
- ✓ Other branches: Build and test, manual deployment approval required

---

## 7. Monitoring & Debugging

### View Pipeline Execution

**Jenkins Classic UI**:
- Jenkins UI → oan-ui-service → Build #<NUMBER>
- Click "Console Output" for detailed logs

**Blue Ocean (Modern UI)**:
- Jenkins UI → Blue Ocean
- Select pipeline from list
- Visual pipeline execution flow
- Click stages for detailed logs

### Check Jenkins Logs

```bash
# Main Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Build-specific logs
cat ~/.jenkins/jobs/oan-ui-service/builds/<BUILD_NUMBER>/log

# Build logs on instance
cat /var/log/oan-ui-service-build.log
```

### Verify Application Deployment

```bash
# Check health endpoint
curl -v http://localhost:5000/health

# Check Nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/access.log

# Check deployment info
cat /opt/deployment-info.txt
```

### Common Issues

#### Issue: Webhook not triggering builds

**Solution**:
1. Verify webhook URL is accessible
   ```bash
   curl -v http://<JENKINS_URL>:8080/github-webhook/
   ```

2. Check recent deliveries in GitHub webhook settings
3. Verify Jenkins firewall allows GitHub access
4. Check Jenkins logs for webhook errors

#### Issue: Coverage not being detected

**Solution**:
1. Verify project has test command in `package.json`
2. Check that test output includes coverage report
3. Review build log: `cat /var/log/oan-ui-service-build.log`
4. Jenkins may need manual coverage parsing configuration

#### Issue: Deployment fails

**Solution**:
1. Check Nginx status: `sudo systemctl status nginx`
2. Review deployment report: `cat /opt/deployment-info.txt`
3. Check app logs: `sudo tail -f /var/log/nginx/error.log`
4. Verify file permissions on `/opt/applications/`

---

## 8. Advanced Configuration

### Environment Variables

Add environment variables to pipeline:

**Jenkins UI → Manage Jenkins → Configure System → Global properties:**

```
NODE_VERSION=18
COVERAGE_THRESHOLD=85
DEPLOYMENT_USER=jenkins
DEPLOYMENT_PATH=/opt/applications/
```

### Build Timeout

Set build timeout to prevent hanging builds:

**Jenkins UI → oan-ui-service → Configure:**
- **Build Timeout**: 30 minutes
- **Timeout Type**: Absolute

### Email Notifications

**Install Email Plugin**:
```bash
sudo systemctl stop jenkins
java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080 \
  install-plugin email-ext
sudo systemctl start jenkins
```

**Configure SMTP** (Jenkins UI → Manage Jenkins → Configure System):
```
SMTP server: smtp.gmail.com (example)
Default user email suffix: @example.com
Advanced: Use SMTP Authentication
```

### Slack Notifications

**Install Slack Plugin**:
```bash
java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080 \
  install-plugin slack
```

**Create Slack Integration** (Slack UI → Create App → Incoming Webhooks):
```
1. Create new Slack workspace channel: #jenkins-builds
2. Add Incoming Webhook
3. Copy webhook URL
```

**Configure Jenkins** (Jenkins UI → oan-ui-service → Configure):
```groovy
post {
    always {
        slackSend(
            channel: '#jenkins-builds',
            color: currentBuild.result == 'SUCCESS' ? 'good' : 'danger',
            message: "${env.BUILD_URL} completed: ${currentBuild.result}"
        )
    }
}
```

---

## 9. Backup & Restore

### Backup Jenkins Configuration

```bash
# Create backup
sudo tar -czf ~/jenkins-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/jobs \
  /var/lib/jenkins/secrets \
  /var/lib/jenkins/plugins

# List backups
ls -la ~/jenkins-backup-*.tar.gz
```

### Restore Jenkins Configuration

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Restore from backup
sudo tar -xzf ~/jenkins-backup-20240115.tar.gz -C /

# Restart Jenkins
sudo systemctl start jenkins
```

---

## 10. Security Best Practices

### Enable Security Matrix

1. Jenkins UI → Manage Jenkins → Configure Global Security
2. **Authorization**: Matrix-based security
3. **Add Users**:
   - Grant developers: Job create, build, read permissions
   - Grant admins: All permissions
4. Click "Save"

### Use Credentials for Secrets

Don't hardcode secrets in Jenkinsfile. Use Jenkins credentials:

```groovy
withCredentials([
    string(credentialsId: 'api-key', variable: 'API_KEY'),
    file(credentialsId: 'deployment-key', variable: 'KEYFILE')
]) {
    sh '''
        export API_KEY=${API_KEY}
        ./deploy.sh
    '''
}
```

### Rotate GitHub Token

Every 90 days or after suspected compromise:

1. GitHub → Settings → Developer settings → Personal access tokens
2. Delete old token
3. Generate new token
4. Update Jenkins credentials

---

## 11. Performance Tuning

### Increase Jenkins Memory

Edit `/etc/default/jenkins`:

```bash
# Find JAVA_ARGS and modify
JAVA_ARGS="-Xmx2048m -Xms1024m"
```

Restart Jenkins:
```bash
sudo systemctl restart jenkins
```

### Parallel Pipeline Execution

Update Jenkinsfile for parallel stages:

```groovy
stage('Tests') {
    parallel {
        stage('Unit Tests') {
            steps { sh 'npm test' }
        }
        stage('Lint') {
            steps { sh 'npm run lint' }
        }
    }
}
```

### Pipeline Caching

Speed up builds with plugin caching:

```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '30'))
}
```

---

## 12. Troubleshooting Checklist

- [ ] Jenkins service is running: `sudo systemctl status jenkins`
- [ ] Port 8080 is accessible: `curl http://localhost:8080`
- [ ] GitHub webhook is configured and active
- [ ] Jenkins has correct GitHub credentials
- [ ] Jenkinsfile exists in repository
- [ ] Test command is defined in package.json
- [ ] Coverage report is generated in test output
- [ ] Nginx is configured for reverse proxy
- [ ] Application port (5000) is open
- [ ] Health check endpoint exists: `/health`

---

## Quick Reference

### Key Ports
- Jenkins: 8080
- Application: 5000
- SSH: 22
- HTTP/HTTPS: 80/443

### Key Directories
- Jenkins home: `/var/lib/jenkins/`
- Job configs: `/var/lib/jenkins/jobs/`
- Build logs: `/var/lib/jenkins/jobs/<JOB>/builds/<NUMBER>/log`
- App deployment: `/opt/applications/oan-ui-service/`
- Deployment info: `/opt/deployment-info.txt`

### Key Files
- Jenkins config: `/etc/default/jenkins`
- Nginx Jenkins: `/etc/nginx/sites-available/jenkins`
- Initial password: `/opt/jenkins-initial-password.txt`
- Cloud-init output: `/var/log/cloud-init-output.log`

### Useful Commands

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View recent builds
ls -la /var/lib/jenkins/jobs/oan-ui-service/builds/

# Test webhook manually
curl -X POST http://<JENKINS_URL>:8080/github-webhook/ \
  -H "Content-Type: application/json" \
  -d '{"action":"opened"}'

# Monitor build in real-time
tail -f /var/lib/jenkins/jobs/oan-ui-service/builds/1/log

# Check deployment
curl -v http://localhost:5000/health
```

---

## Support Resources

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Blue Ocean UI**: https://www.jenkins.io/doc/book/blueocean/
- **GitHub Actions vs Jenkins**: https://docs.github.com/en/actions
- **Pipeline Best Practices**: https://www.jenkins.io/doc/book/pipeline/

---

## Next Steps

1. ✓ Jenkins installation (via cloud-init)
2. ✓ Initial admin password saved
3. → Complete setup wizard on first access
4. → Add GitHub credentials
5. → Create pipeline jobs
6. → Configure GitHub webhooks
7. → Test pipeline with commit to main branch
8. → Monitor builds and deployments

---

**Version**: 1.0  
**Last Updated**: 2024-01-15  
**Maintainer**: CI/CD Team
