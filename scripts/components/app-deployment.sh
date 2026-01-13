#!/bin/bash
# Node.js and Application Deployment Component

deploy_applications() {
  local log_file="${1:-/var/log/app-deployment.log}"
  
  echo "Starting application deployment phase..." | tee -a "$log_file"
  
  # Install Node.js v18
  echo "Installing Node.js..." | tee -a "$log_file"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - >> "$log_file" 2>&1
  apt-get install -y nodejs >> "$log_file" 2>&1
  echo "Node.js installed: $(node --version)" | tee -a "$log_file"
  
  # Setup application directories
  APPS_DIR="/opt/applications"
  OAN_DIR="$APPS_DIR/oan-ui-service"
  AGRI_DIR="$APPS_DIR/agri_help"
  mkdir -p "$APPS_DIR"
  
  # Deploy OAN UI Service
  OAN_DEPLOYED=false
  echo "Deploying OAN UI Service..." | tee -a "$log_file"
  if clone_repo "https://github.com/the-swag-coder/oan-ui-service" "$OAN_DIR" "OAN UI Service"; then
    cd "$OAN_DIR"
    if npm install >> "$log_file" 2>&1 && npm run build >> "$log_file" 2>&1; then
      echo "✓ OAN UI Service built successfully" | tee -a "$log_file"
      OAN_DEPLOYED=true
    else
      echo "✗ OAN UI Service build failed" | tee -a "$log_file"
    fi
  fi
  
  # Deploy Agri Help
  AGRI_DEPLOYED=false
  echo "Deploying Agri Help..." | tee -a "$log_file"
  if clone_repo "https://github.com/Sulopatech/agri_help" "$AGRI_DIR" "Agri Help"; then
    cd "$AGRI_DIR"
    if npm install >> "$log_file" 2>&1; then
      # Conditional build if package.json has build script
      if [ -f "package.json" ] && grep -q '"build"' package.json; then
        if npm run build >> "$log_file" 2>&1; then
          echo "✓ Agri Help built successfully" | tee -a "$log_file"
        fi
      fi
      AGRI_DEPLOYED=true
    else
      echo "✗ Agri Help npm install failed" | tee -a "$log_file"
    fi
  fi
  
  # Export deployment status for other components
  export OAN_DEPLOYED
  export AGRI_DEPLOYED
}
