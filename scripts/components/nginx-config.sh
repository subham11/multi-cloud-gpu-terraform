#!/bin/bash
# Nginx Web Server Configuration Component

configure_nginx() {
  local log_file="${1:-/var/log/app-deployment.log}"
  
  echo "Configuring Nginx web server..." | tee -a "$log_file"
  
  # Install Nginx if not already installed
  if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
  fi
  
  # Generate Nginx configuration
  cat > /etc/nginx/sites-available/multi-cloud-apps << 'NGINX_CONFIG'
# OAN UI Service - Port 5000
server {
    listen 5000;
    listen [::]:5000;
    
    root /opt/applications/oan-ui-service/dist;
    index index.html;
    
    server_name _;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    # React Router - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# Agri Help - Port 3000
server {
    listen 3000;
    listen [::]:3000;
    
    root /opt/applications/agri_help;
    index index.html;
    
    server_name _;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    # Try static files first, then proxy to Node.js backend
    location / {
        try_files $uri $uri/ @proxy;
    }
    
    # Proxy to Node.js application on port 4000
    location @proxy {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_CONFIG
  
  # Enable the site
  ln -sf /etc/nginx/sites-available/multi-cloud-apps /etc/nginx/sites-enabled/multi-cloud-apps
  rm -f /etc/nginx/sites-enabled/default
  
  # Test configuration
  if nginx -t >> "$log_file" 2>&1; then
    echo "✓ Nginx configuration valid" | tee -a "$log_file"
  else
    echo "✗ Nginx configuration test failed" | tee -a "$log_file"
    return 1
  fi
  
  # Restart Nginx
  systemctl restart nginx
  systemctl enable nginx
  
  echo "✓ Nginx configured and started" | tee -a "$log_file"
  
  # Verify applications
  sleep 3
  if [ "$OAN_DEPLOYED" = true ]; then
    if curl -sf http://localhost:5000/health > /dev/null; then
      echo "✓ OAN UI Service health check passed" | tee -a "$log_file"
    else
      echo "⚠ OAN UI Service health check failed" | tee -a "$log_file"
    fi
  fi
  
  if [ "$AGRI_DEPLOYED" = true ]; then
    if curl -sf http://localhost:3000/health > /dev/null; then
      echo "✓ Agri Help health check passed" | tee -a "$log_file"
    else
      echo "⚠ Agri Help health check failed" | tee -a "$log_file"
    fi
  fi
}
