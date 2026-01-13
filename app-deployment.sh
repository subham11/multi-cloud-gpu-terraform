#!/bin/bash

################################################################################
# Application Deployment Script
# Deploys OAN UI Service and other applications on cloud instances
# This script runs as part of cloud-init after NVIDIA drivers installation
################################################################################

set -e

# Logging function
log_msg() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/app-deployment.log
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a /var/log/app-deployment.log
  exit 1
}

# Track deployment info
DEPLOYMENT_INFO_FILE="/opt/deployment-info.txt"
APPS_DIR="/opt/applications"
mkdir -p "$APPS_DIR"

{
  echo "=========================================="
  echo "APPLICATION DEPLOYMENT REPORT"
  echo "=========================================="
  echo "Deployment Time: $(date)"
  echo ""
} > "$DEPLOYMENT_INFO_FILE"

log_msg "Starting application deployment..."

# Install Node.js if not present
if ! command -v node &> /dev/null; then
  log_msg "Installing Node.js v18..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
  log_msg "Node.js installed: $(node --version)"
fi

npm --version > /dev/null || log_error "npm is not installed"

# ============================================================================
# 1. Deploy OAN UI Service
# ============================================================================

log_msg "Deploying OAN UI Service..."

OAN_APP_DIR="$APPS_DIR/oan-ui-service"
OAN_PORT=5000
OAN_BUILD_DIR="$OAN_APP_DIR/dist"
OAN_PID_FILE="/var/run/oan-ui-service.pid"

mkdir -p "$OAN_APP_DIR"

# Clone repository
if [ ! -d "$OAN_APP_DIR/.git" ]; then
  log_msg "Cloning OAN UI Service repository..."
  cd "$OAN_APP_DIR"
  git clone https://github.com/the-swag-coder/oan-ui-service . 2>&1 | tee -a /var/log/app-deployment.log || \
    log_error "Failed to clone OAN UI Service"
else
  log_msg "OAN UI Service already cloned, updating..."
  cd "$OAN_APP_DIR"
  git pull origin main 2>&1 | tee -a /var/log/app-deployment.log || true
fi

# Install dependencies
log_msg "Installing OAN UI Service dependencies..."
cd "$OAN_APP_DIR"
npm install 2>&1 | tee -a /var/log/app-deployment.log || \
  log_error "Failed to install OAN dependencies"

# Build for production
log_msg "Building OAN UI Service for production..."
npm run build 2>&1 | tee -a /var/log/app-deployment.log || \
  log_error "Failed to build OAN UI Service"

# Setup Nginx to serve the application
log_msg "Configuring Nginx for OAN UI Service..."

# Create Nginx configuration
cat > /etc/nginx/sites-available/oan-ui-service << 'NGINX_CONF'
server {
    listen 5000;
    server_name _;

    # OAN UI Service - Static files
    root /opt/applications/oan-ui-service/dist;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;

    # Static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # API proxy (if backend available)
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONF

log_msg "Nginx configuration created for OAN UI Service"

# ============================================================================
# 2. Prepare for additional applications
# ============================================================================

log_msg "Preparing for additional application deployments..."

# Create placeholder for agri_help deployment
cat > "$APPS_DIR/agri_help_placeholder.txt" << 'PLACEHOLDER'
# Agri Help Deployment Placeholder
#
# When agri_help repository becomes available, deployment script will:
# 1. Clone the repository
# 2. Analyze dependencies (check for package.json, requirements.txt, etc.)
# 3. Install runtime environment (Node.js, Python, etc.)
# 4. Build the application
# 5. Configure Nginx reverse proxy
# 6. Start the application service
#
# Check /var/log/app-deployment.log for status updates
PLACEHOLDER

# ============================================================================
# 3. Test Nginx configuration and start services
# ============================================================================

log_msg "Testing Nginx configuration..."
nginx -t 2>&1 | tee -a /var/log/app-deployment.log || \
  log_error "Nginx configuration test failed"

log_msg "Starting Nginx service..."
systemctl restart nginx || log_error "Failed to start Nginx"
systemctl enable nginx

log_msg "Verifying Nginx is running..."
sleep 2
curl -f http://localhost:5000/health > /dev/null || \
  log_error "Failed to reach OAN UI Service health endpoint"

# ============================================================================
# 4. Generate deployment report
# ============================================================================

log_msg "Generating deployment report..."

{
  echo ""
  echo "DEPLOYMENT STATUS: SUCCESS"
  echo ""
  echo "=========================================="
  echo "DEPLOYED APPLICATIONS"
  echo "=========================================="
  echo ""
  echo "1. OAN UI Service"
  echo "   ✓ Status: RUNNING"
  echo "   ✓ Location: $OAN_APP_DIR"
  echo "   ✓ Build Directory: $OAN_BUILD_DIR"
  echo "   ✓ Port: $OAN_PORT (Nginx)"
  echo "   ✓ Service: nginx"
  echo "   ✓ Health Check: /health"
  echo "   ✓ Repository: https://github.com/the-swag-coder/oan-ui-service"
  echo ""
  echo "   Tech Stack:"
  echo "   - Framework: React"
  echo "   - Language: TypeScript"
  echo "   - Build Tool: Vite"
  echo "   - CSS: Tailwind CSS"
  echo "   - Components: shadcn-ui"
  echo "   - Node.js: $(node --version)"
  echo "   - npm: $(npm --version)"
  echo ""
  echo "=========================================="
  echo "PENDING APPLICATIONS"
  echo "=========================================="
  echo ""
  echo "2. Agri Help"
  echo "   ✗ Status: AWAITING DEPLOYMENT"
  echo "   ✗ Reason: Repository not found (404)"
  echo "   ⓘ Action: Verify repository URL and deploy when available"
  echo ""
  echo "=========================================="
  echo "SERVICE INFORMATION"
  echo "=========================================="
  echo ""
  echo "OAN UI Service Details:"
  echo "  URL: http://LOAD_BALANCER_IP:80/"
  echo "  Direct Port: http://INSTANCE_IP:5000"
  echo "  Logs: /var/log/nginx/access.log, /var/log/nginx/error.log"
  echo "  App Logs: /var/log/app-deployment.log"
  echo ""
  echo "Authentication:"
  echo "  Method: JWT (RS256)"
  echo "  Required Token Format: ?token=YOUR_JWT_TOKEN"
  echo "  Demo Keys: Available in repository README"
  echo ""
  echo "API Endpoints:"
  echo "  Text-to-Speech: /api/tts/"
  echo "  Speech Recognition: /api/transcribe/"
  echo ""
  echo "=========================================="
  echo "NGINX STATUS"
  echo "=========================================="
  echo ""
  echo "Service Status:"
  systemctl status nginx --no-pager | head -10
  echo ""
  echo "Listening Ports:"
  netstat -tlnp | grep -E 'nginx|LISTEN' || true
  echo ""
  echo "=========================================="
  echo "DEPLOYMENT LOGS"
  echo "=========================================="
  echo ""
  echo "For full deployment logs, see:"
  echo "  /var/log/app-deployment.log"
  echo ""
  echo "For Nginx errors, see:"
  echo "  /var/log/nginx/error.log"
  echo ""
  echo "=========================================="
  echo "VERIFICATION COMMANDS"
  echo "=========================================="
  echo ""
  echo "Check application status:"
  echo "  curl -I http://localhost:5000/health"
  echo ""
  echo "View deployment logs:"
  echo "  sudo tail -f /var/log/app-deployment.log"
  echo ""
  echo "View Nginx logs:"
  echo "  sudo tail -f /var/log/nginx/access.log"
  echo ""
  echo "Restart services:"
  echo "  sudo systemctl restart nginx"
  echo ""
  echo "=========================================="
  echo "Deployment completed at: $(date)"
  echo "=========================================="
} >> "$DEPLOYMENT_INFO_FILE"

# Display the report
cat "$DEPLOYMENT_INFO_FILE" | tee -a /var/log/app-deployment.log

log_msg "Application deployment completed successfully!"

# Make report accessible via web
cp "$DEPLOYMENT_INFO_FILE" /opt/applications/deployment-report.txt
chmod 644 /opt/applications/deployment-report.txt

exit 0
