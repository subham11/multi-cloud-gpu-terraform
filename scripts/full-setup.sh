#!/bin/bash
# Multi-Cloud GPU Infrastructure - Main Setup Orchestrator
# This script coordinates all setup components

set -e

echo "=========================================="
echo "Multi-Cloud GPU Infrastructure Setup"
echo "=========================================="
echo "Start time: $(date)"
echo ""

# ============================================================================
# SYSTEM PREPARATION
# ============================================================================

echo "Phase 1: System Preparation"
echo "----------------------------"

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install base dependencies
echo "Installing base dependencies..."
apt-get install -y \
  build-essential \
  curl \
  wget \
  git \
  nginx \
  net-tools \
  lsb-release

echo "✓ System preparation completed"
echo ""

# ============================================================================
# LOAD COMPONENT SCRIPTS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="${SCRIPT_DIR}/components"

# Source all component scripts
if [ -d "$COMPONENTS_DIR" ]; then
  echo "Loading component scripts from $COMPONENTS_DIR"
  for component in "$COMPONENTS_DIR"/*.sh; do
    if [ -f "$component" ]; then
      echo "  - Loading $(basename "$component")"
      source "$component"
    fi
  done
  echo "✓ All components loaded"
else
  echo "⚠ Components directory not found, using inline functions"
fi

echo ""

# ============================================================================
# NVIDIA DRIVERS AND CUDA
# ============================================================================

echo "Phase 2: NVIDIA Drivers and CUDA"
echo "---------------------------------"

if command -v install_nvidia_drivers &> /dev/null; then
  install_nvidia_drivers
else
  echo "⚠ NVIDIA installation function not found, skipping..."
fi

echo ""

# ============================================================================
# GIT CREDENTIALS
# ============================================================================

echo "Phase 3: Git Credentials Setup"
echo "-------------------------------"

if command -v load_git_credentials &> /dev/null; then
  load_git_credentials
else
  echo "⚠ Git credentials function not found, skipping..."
fi

echo ""

# ============================================================================
# APPLICATION DEPLOYMENT
# ============================================================================

echo "Phase 4: Application Deployment"
echo "--------------------------------"

APP_LOG="/var/log/app-deployment.log"

if command -v deploy_applications &> /dev/null; then
  deploy_applications "$APP_LOG"
else
  echo "⚠ Application deployment function not found, skipping..."
  OAN_DEPLOYED=false
  AGRI_DEPLOYED=false
fi

echo ""

# ============================================================================
# NGINX WEB SERVER
# ============================================================================

echo "Phase 5: Nginx Web Server Configuration"
echo "----------------------------------------"

if command -v configure_nginx &> /dev/null; then
  configure_nginx "$APP_LOG"
else
  echo "⚠ Nginx configuration function not found, skipping..."
fi

echo ""

# ============================================================================
# JENKINS CI/CD
# ============================================================================

echo "Phase 6: Jenkins CI/CD Installation"
echo "------------------------------------"

JENKINS_LOG="/var/log/jenkins-setup.log"

if command -v install_jenkins &> /dev/null; then
  install_jenkins "$JENKINS_LOG"
else
  echo "⚠ Jenkins installation function not found, skipping..."
fi

echo ""

# ============================================================================
# DEPLOYMENT REPORT
# ============================================================================

echo "Phase 7: Generating Deployment Report"
echo "--------------------------------------"

if command -v generate_deployment_report &> /dev/null; then
  generate_deployment_report
else
  echo "⚠ Deployment report function not found, skipping..."
fi

echo ""

# ============================================================================
# COMPLETION
# ============================================================================

echo "=========================================="
echo "Setup Completed Successfully!"
echo "=========================================="
echo "End time: $(date)"
echo ""
echo "Deployment information saved to: /opt/deployment-info.txt"
echo "Jenkins credentials saved to: /opt/jenkins-credentials.txt"
echo ""
echo "Log files:"
echo "  - Bootstrap: /var/log/bootstrap.log"
echo "  - Applications: /var/log/app-deployment.log"
echo "  - Jenkins: /var/log/jenkins-setup.log"
echo ""
echo "Access your applications:"
echo "  - OAN UI Service: http://LOAD_BALANCER_IP/"
echo "  - Agri Help: http://INSTANCE_IP:3000"
echo "  - Jenkins: http://INSTANCE_IP:8080 (admin/admin123)"
echo ""
echo "=========================================="
