#!/bin/bash
# Deployment Report Generation Component

generate_deployment_report() {
  local report_file="/opt/deployment-info.txt"
  
  cat > "$report_file" << 'REPORT_HEADER'
========================================
MULTI-CLOUD GPU INFRASTRUCTURE
========================================
Deployment Time: $(date)

SYSTEM INFORMATION
========================================
OS: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Node.js: $(node --version 2>/dev/null || echo "Not installed")
NPM: $(npm --version 2>/dev/null || echo "Not installed")
Java: $(java -version 2>&1 | head -1)

GPU INFORMATION
========================================
REPORT_HEADER

  # Add GPU info if available
  if command -v nvidia-smi &> /dev/null; then
    nvidia-smi >> "$report_file"
  else
    echo "No NVIDIA GPU detected or drivers not installed" >> "$report_file"
  fi
  
  cat >> "$report_file" << 'REPORT_APPS'

DEPLOYED APPLICATIONS
========================================
REPORT_APPS

  # OAN UI Service status
  if [ "$OAN_DEPLOYED" = true ]; then
    cat >> "$report_file" << 'OAN_SUCCESS'
1. OAN UI Service
   Status: DEPLOYED ✓
   Port: 5000 (via Nginx)
   Repository: https://github.com/the-swag-coder/oan-ui-service
   Health: http://localhost:5000/health
   Access: via Load Balancer on port 80/443
OAN_SUCCESS
  else
    cat >> "$report_file" << 'OAN_FAILED'
1. OAN UI Service
   Status: DEPLOYMENT FAILED ✗
   Reason: Repository clone or build failed
OAN_FAILED
  fi
  
  # Agri Help status
  if [ "$AGRI_DEPLOYED" = true ]; then
    cat >> "$report_file" << AGRI_SUCCESS
2. Agri Help
   Status: DEPLOYED ✓
   Port: 3000 (via Nginx)
   Repository: https://github.com/Sulopatech/agri_help
   Health: http://localhost:3000/health
   Git Credentials: Used ${GIT_USERNAME}
AGRI_SUCCESS
  else
    cat >> "$report_file" << AGRI_FAILED
2. Agri Help
   Status: DEPLOYMENT FAILED ✗
   Reason: Repository not accessible
   Provided Git Username: ${GIT_USERNAME}
AGRI_FAILED
  fi
  
  cat >> "$report_file" << 'REPORT_JENKINS'

CI/CD SYSTEM
========================================
Jenkins: http://localhost:8080
Username: admin
Password: admin123
Credentials File: /opt/jenkins-credentials.txt

Pipeline Jobs:
- oan-ui-service (auto-configured)

VERIFICATION COMMANDS
========================================
# Check services
systemctl status nginx
systemctl status jenkins

# Test applications
curl http://localhost:5000/health
curl http://localhost:3000/health
curl http://localhost:8080/login

# View logs
tail -f /var/log/app-deployment.log
tail -f /var/log/jenkins-setup.log
tail -f /var/log/nginx/error.log

========================================
Deployment completed: $(date)
========================================
REPORT_JENKINS

  echo "✓ Deployment report generated: $report_file"
}
