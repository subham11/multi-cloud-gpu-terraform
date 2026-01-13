# 🚀 Single-Click Deployment Guide

## Overview

This project provides a **TRUE SINGLE-CLICK DEPLOYMENT** that sets up a complete multi-cloud GPU infrastructure with CI/CD pipelines, NVIDIA drivers, and your applications - all automatically.

## What Gets Deployed

✅ **Infrastructure (Auto-deployed via Terraform)**
- Multi-cloud GPU instances (AWS g5.4xlarge / Azure NV36ads / GCP g2-standard)
- Load balancers (AWS ALB / Azure LB / GCP Global LB)
- Security groups with proper firewall rules
- Networking (VPC, subnets, internet gateways)

✅ **GPU Stack (Auto-installed via cloud-init)**
- NVIDIA Driver 550
- CUDA Toolkit 12.4
- Automatic GPU detection

✅ **Application Stack (Auto-deployed)**
- Node.js v18 from NodeSource
- OAN UI Service (React + Vite + TypeScript)
- Nginx reverse proxy (port 5000)
- Health check endpoint (/health)

✅ **Jenkins CI/CD (Fully Auto-Configured)**
- Jenkins server (port 8080)
- Setup wizard SKIPPED automatically
- Admin user PRE-CREATED: `admin/admin123`
- Plugins PRE-INSTALLED: git, github, workflow-aggregator, blueocean, junit
- Pipeline job PRE-CREATED: oan-ui-service
- Ready to build immediately after deployment

## 🎯 One-Click Deployment

### Step 1: Run Deploy Script

```bash
./deploy.sh
```

That's it! The script will:
1. Ask you to select cloud provider (AWS/Azure/GCP)
2. Ask you to select region
3. Ask you for VM name
4. Run Terraform to create all infrastructure
5. Automatically configure everything on the instance

### Step 2: Wait (35-50 minutes)

The deployment timeline:
- **Instance boot**: 2-5 minutes
- **NVIDIA drivers + CUDA**: 10-15 minutes  
- **Node.js v18**: 2-3 minutes
- **OAN UI Service**: 5-10 minutes
- **Jenkins installation**: 5-10 minutes
- **Jenkins auto-configuration**: 5-10 minutes

### Step 3: Access Your Services

After deployment completes, you'll get all URLs automatically:

**Application:**
- Load Balancer URL: `http://<LB_DNS>/`
- Direct Access: `http://<INSTANCE_IP>:5000`
- Health Check: `http://<LB_DNS>:5000/health`

**Jenkins CI/CD:**
- URL: `http://<INSTANCE_IP>:8080`
- Username: `admin`
- Password: `admin123`

### Step 4: Build Your Application

1. Open Jenkins: `http://<INSTANCE_IP>:8080`
2. Login with `admin/admin123`
3. Click on "oan-ui-service" job
4. Click "Build Now"
5. Watch the pipeline execute (11 stages)

✅ Done! Your application is deployed with CI/CD.

## 🔧 What Was Auto-Configured

### Jenkins Configuration (NO MANUAL SETUP REQUIRED)

The following were configured automatically via Groovy init scripts:

1. **Setup Wizard**: Skipped entirely
2. **Admin User**: Created automatically
   - Username: `admin`
   - Password: `admin123` (change after first login)
3. **Security**: Configured with proper authentication
4. **Plugins**: Auto-installed via Jenkins CLI
   - git
   - github
   - github-api
   - workflow-aggregator
   - blueocean
   - junit
5. **Pipeline Job**: Pre-created for OAN UI Service
   - Repository: https://github.com/the-swag-coder/oan-ui-service
   - Branch: main
   - Jenkinsfile: Auto-detected

## 📋 Post-Deployment Tasks

### Monitor Installation Progress

**AWS:**
```bash
ssh -i your-key.pem ubuntu@<INSTANCE_IP>
sudo tail -f /var/log/cloud-init-output.log
```

**Azure:**
```bash
ssh -i your-key.pem azureuser@<INSTANCE_IP>
sudo tail -f /var/log/cloud-init-output.log
```

**GCP:**
```bash
gcloud compute ssh <VM_NAME> --zone <ZONE>
sudo tail -f /var/log/cloud-init-output.log
```

### View Specific Component Logs

```bash
# Application deployment
sudo tail -f /var/log/app-deployment.log

# Jenkins setup
sudo tail -f /var/log/jenkins-setup.log

# Nginx
sudo tail -f /var/log/nginx/access.log
```

### Verify All Components

```bash
# Check application
curl http://localhost:5000/health

# Check Jenkins
curl http://localhost:8080/login

# Check NVIDIA drivers (if GPU instance)
nvidia-smi

# Check services
systemctl status nginx
systemctl status jenkins
```

## 🔐 Security Notes

### Change Default Credentials

**IMPORTANT**: After first login, change the Jenkins password:

1. Login to Jenkins
2. Click "admin" → "Configure"
3. Update password
4. Save

### View Saved Credentials

On the instance:
```bash
cat /opt/jenkins-credentials.txt
```

### Firewall Rules

The deployment automatically configures:
- Port 5000: Application (from Load Balancer only)
- Port 8080: Jenkins (from anywhere)
- Port 80/443: Load Balancer (from anywhere)
- Port 22: SSH (from anywhere - consider restricting)

## 🔄 GitHub Webhook (Optional)

For automatic builds when you push to GitHub:

1. Go to your repository settings:
   ```
   https://github.com/the-swag-coder/oan-ui-service/settings/hooks
   ```

2. Add webhook:
   - Payload URL: `http://<INSTANCE_IP>:8080/github-webhook/`
   - Content type: `application/json`
   - Which events: Select "Just the push event"

3. Save

Now, every push to `main` branch will automatically trigger a Jenkins build.

## 📊 CI/CD Pipeline Stages

The oan-ui-service pipeline includes:

1. **Checkout**: Clone repository
2. **Install Dependencies**: `npm install`
3. **Lint**: Code quality checks
4. **Unit Tests**: Run test suite
5. **Coverage Check**: Enforce 85% minimum
6. **Build**: `npm run build`
7. **Archive**: Save build artifacts
8. **Deploy**: Copy to `/opt/applications/oan-ui-service/dist/`
9. **Restart Services**: Reload Nginx
10. **Health Check**: Verify deployment
11. **Notification**: Report status

## 🛠️ Troubleshooting

### Deployment Report

View the comprehensive deployment report on the instance:
```bash
cat /opt/deployment-info.txt
```

This shows:
- Deployment timestamp
- All installed components
- Service statuses
- Access URLs
- Verification commands

### Common Issues

**Jenkins not starting:**
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

**Application not accessible:**
```bash
sudo nginx -t
sudo systemctl status nginx
curl http://localhost:5000/health
```

**NVIDIA drivers not loaded:**
```bash
lspci | grep -i nvidia
dmesg | grep -i nvidia
sudo modprobe nvidia
```

### Manual Configuration Reset

If you need to reconfigure Jenkins:
```bash
sudo systemctl stop jenkins
sudo rm -rf /var/lib/jenkins/init.groovy.d/
sudo systemctl start jenkins
```

## 📚 Additional Documentation

For more detailed information:

- [Jenkins Setup Guide](readme/JENKINS_SETUP_GUIDE.md)
- [Jenkins Quick Start](readme/JENKINS_QUICK_START.md)
- [GitHub Webhook Setup](readme/GITHUB_WEBHOOK_SETUP.md)
- [CI/CD Pipeline Workflow](readme/CI-CD_PIPELINE_WORKFLOW.md)
- [Application Deployment Guide](readme/APP_DEPLOYMENT_GUIDE.md)
- [NVIDIA CUDA Deployment](readme/NVIDIA_CUDA_DEPLOYMENT.md)

## ⚡ Key Benefits

### True Single-Click
- No manual configuration steps
- No wizard completion required
- No plugin selection needed
- No job creation required
- Just run `./deploy.sh` and wait

### Zero Pre-requisites
- No Jenkins installation required
- No Docker setup needed
- No Kubernetes configuration
- Everything deployed fresh

### Production-Ready
- Proper security configuration
- Health checks configured
- Load balancers in place
- Monitoring-ready logs

### CI/CD Out-of-the-Box
- 11-stage pipeline ready
- 85% coverage enforcement
- Automatic deployment
- Health check validation

## 🎉 Success Indicators

You'll know everything is working when:

✅ `curl http://<INSTANCE_IP>:5000/health` returns `OK`
✅ Jenkins UI accessible at `http://<INSTANCE_IP>:8080`
✅ Login with `admin/admin123` succeeds
✅ "oan-ui-service" job visible in Jenkins
✅ "Build Now" triggers pipeline successfully
✅ Application accessible via Load Balancer URL

## 💡 Pro Tips

1. **Save Your Instance IP**: You'll need it for Jenkins and SSH access
2. **Bookmark Jenkins URL**: `http://<INSTANCE_IP>:8080`
3. **Setup Webhook Early**: For automatic builds on every push
4. **Monitor First Build**: Watch the pipeline to understand the workflow
5. **Change Password**: Update admin password immediately after first login
6. **Check Logs**: Use `tail -f` to monitor real-time progress
7. **Test Health Check**: Verify `/health` endpoint before using application

## 🚦 What's Next?

After successful deployment:

1. ✅ Change Jenkins admin password
2. ✅ Setup GitHub webhook (optional)
3. ✅ Trigger first build manually
4. ✅ Verify application deployment
5. ✅ Configure custom domain (optional)
6. ✅ Setup SSL certificate (optional)
7. ✅ Add monitoring/alerting (optional)

## 📞 Support

Check deployment logs at:
- `/var/log/cloud-init-output.log` - Full cloud-init log
- `/var/log/app-deployment.log` - Application deployment
- `/var/log/jenkins-setup.log` - Jenkins configuration
- `/opt/deployment-info.txt` - Deployment summary

---

**Remember**: This is a **COMPLETE SINGLE-CLICK DEPLOYMENT**. No manual configuration, no wizard completion, no job creation. Just run `./deploy.sh` and everything is ready!
