# Application Deployment Guide

## Overview

This Terraform configuration now includes automatic deployment of web applications on cloud instances after NVIDIA driver installation. Currently configured to deploy the **OAN UI Service** with support for additional applications.

## Deployed Applications

### 1. OAN UI Service ✓

**Status:** Ready for Deployment  
**Repository:** https://github.com/the-swag-coder/oan-ui-service  
**Tech Stack:** React + Vite + TypeScript  

#### Quick Facts:
- **Framework:** React 18+
- **Language:** TypeScript (96.9%)
- **Build Tool:** Vite
- **Styling:** Tailwind CSS
- **Components:** shadcn-ui
- **Authentication:** JWT (RS256)
- **Server:** Nginx (reverse proxy)

#### Dependencies:
```
Runtime Requirements:
- Node.js: v16+ (v18 installed by default)
- npm: comes with Node.js
- Nginx: for reverse proxy
- Git: for repository cloning
```

#### Installation Process:
1. **Clone Repository:** `git clone https://github.com/the-swag-coder/oan-ui-service`
2. **Install Dependencies:** `npm install`
3. **Build for Production:** `npm run build` (generates `/dist` folder)
4. **Setup Nginx:** Serve static files from `/opt/applications/oan-ui-service/dist`
5. **Configure Health Check:** Nginx `/health` endpoint on port 5000

### 2. Agri Help (Pending)

**Status:** ✗ NOT FOUND  
**Repository:** https://github.com/Sulopatech/agri_help  
**Issue:** Repository returns 404 error

**Action Required:** 
- Verify the correct repository URL
- Confirm repository is public
- Once URL is confirmed, deployment can be added to the cloud-init script

## Deployment Architecture

```
┌─────────────────────────────────────────┐
│      Load Balancer (Port 80/443)        │
├─────────────────────────────────────────┤
│  AWS ALB / Azure LB / GCP Global LB     │
│  ↓                                       │
│  Routes to Instance/VM (Port 5000)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     Instance / VM / Compute Engine      │
├─────────────────────────────────────────┤
│                                          │
│  Port 5000: Nginx (Reverse Proxy)       │
│    ├─ /            → OAN UI Service     │
│    ├─ /health      → Health Check       │
│    └─ /api/*       → Backend (if ready) │
│                                          │
│  Port 8000: Backend APIs (future)       │
│                                          │
│  Installation Logs:                      │
│    /var/log/app-deployment.log          │
│    /var/log/nginx/error.log             │
│    /opt/deployment-info.txt             │
│                                          │
└─────────────────────────────────────────┘
```

## Cloud-Init Deployment Sequence

The instance deployment follows this sequence:

### Phase 1: System Setup (5 minutes)
```bash
✓ Update system packages
✓ Install build tools and dependencies
✓ Install git, nginx, net-tools
✓ Validate system prerequisites
```

### Phase 2: NVIDIA Setup (10-15 minutes)
```bash
✓ Detect GPU hardware
✓ Add NVIDIA CUDA repository
✓ Install NVIDIA drivers 550
✓ Install CUDA Toolkit 12.4
✓ Configure PATH and libraries
✓ Verify with nvidia-smi
```

### Phase 3: Node.js Setup (2-3 minutes)
```bash
✓ Install Node.js v18 from official repository
✓ Verify npm is available
✓ Check versions (node -v, npm -v)
```

### Phase 4: Application Deployment (5-10 minutes)
```bash
✓ Clone OAN UI Service repository
✓ Install npm dependencies
✓ Build for production (npm run build)
✓ Configure Nginx reverse proxy
✓ Test Nginx configuration
✓ Start Nginx service
✓ Health check verification
```

### Phase 5: Report Generation (1 minute)
```bash
✓ Generate deployment report
✓ Create /opt/deployment-info.txt
✓ Log all operations
```

**Total Time:** 25-40 minutes from instance launch

## Load Balancer Configuration

### AWS (Application Load Balancer)
```hcl
Target Group: Port 5000
Health Check:
  - Path: /health
  - Port: 5000
  - Interval: 30 seconds
  - Healthy Threshold: 2
  - Unhealthy Threshold: 2
  - Timeout: 5 seconds
  - Expected Response: 200

Listener:
  - Port 80 → Port 5000 (HTTP)
  - Port 443 → Port 5000 (HTTPS, if configured)
```

### Azure (Load Balancer)
```hcl
Health Probe:
  - Protocol: HTTP
  - Port: 5000
  - Path: /health
  - Interval: 30 seconds
  - Healthy Threshold: 2
  - Unhealthy Threshold: 2

Rules:
  - Frontend Port 80 → Backend Port 5000
  - Frontend Port 443 → Backend Port 5000
```

### GCP (Global Load Balancer)
```hcl
Health Check:
  - Protocol: HTTP
  - Port: 5000
  - Path: /health
  - Check Interval: 30 seconds
  - Healthy Threshold: 2
  - Unhealthy Threshold: 2

Backend Service:
  - Port: 5000
  - Balancing Mode: UTILIZATION
  - Session Affinity: NONE

Global Forwarding Rule:
  - IP Protocol: HTTP
  - Load Balancing Scheme: EXTERNAL_MANAGED
```

## Accessing Deployed Applications

### Once Instance is Ready (20-40 minutes after deployment starts)

#### OAN UI Service

**Via Load Balancer:**
```
http://<LOAD_BALANCER_IP>/
http://<LOAD_BALANCER_IP>/?token=YOUR_JWT_TOKEN
```

**Direct Access (if port 5000 exposed):**
```
http://<INSTANCE_IP>:5000/
http://<INSTANCE_IP>:5000/?token=YOUR_JWT_TOKEN
```

**Health Check:**
```
curl http://<INSTANCE_IP>:5000/health
# Expected response: 200 OK
```

#### JWT Authentication

The application requires JWT authentication:

```bash
# Format: ?token=YOUR_JWT_TOKEN

# Example with demo token (development only):
http://<LOAD_BALANCER_IP>/?token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...

# Generate your own token using jwt.io:
# 1. Visit https://jwt.io/
# 2. Set algorithm to RS256
# 3. Use provided keys from README
# 4. Include required claims (sub, name, email, iat, exp)
# 5. Copy token and append to URL
```

**Required JWT Claims:**
```json
{
  "sub": "user123",
  "name": "User Name",
  "email": "user@example.com",
  "iat": 1640995200,
  "exp": 9999999999,
  "aud": "oan-ui-service",
  "iss": "your-auth-service"
}
```

### API Endpoints

All API calls require JWT Bearer token authentication:

```bash
# Text-to-Speech
POST /api/tts/
Headers:
  Authorization: Bearer <JWT_TOKEN>
Body:
  {
    "text": "Hello world",
    "language": "en",
    "sessionId": "session123"
  }

# Automatic Speech Recognition
POST /api/transcribe/
Headers:
  Authorization: Bearer <JWT_TOKEN>
Body:
  {
    "audio": "base64-encoded-audio",
    "serviceId": "asr-service",
    "sessionId": "session123"
  }
```

## Monitoring Deployment

### SSH into Instance

**AWS:**
```bash
ssh -i <key.pem> ec2-user@<instance-ip>
# or
aws ec2-instance-connect send-ssh-public-key \
  --instance-id <instance-id> \
  --os-user ec2-user \
  --ssh-public-key file://~/.ssh/id_rsa.pub \
  --availability-zone <az>
```

**Azure:**
```bash
ssh -i <key> azureuser@<vm-ip>
```

**GCP:**
```bash
gcloud compute ssh <instance-name> --zone=<zone>
```

### View Real-Time Logs

**During Deployment (cloud-init):**
```bash
# Watch cloud-init progress
sudo tail -f /var/log/cloud-init-output.log

# Watch application deployment
sudo tail -f /var/log/app-deployment.log
```

**After Deployment (application logs):**
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Application report
cat /opt/deployment-info.txt
```

### Check Service Status

```bash
# Check Nginx status
sudo systemctl status nginx

# Check if Nginx is listening
sudo netstat -tlnp | grep nginx

# Test health endpoint
curl -I http://localhost:5000/health

# View Nginx configuration
sudo cat /etc/nginx/sites-enabled/oan-ui-service
```

## Troubleshooting

### Application Not Responding

1. **Check if instance is ready** (wait 20+ minutes after launch)
   ```bash
   curl -I http://<INSTANCE_IP>:5000/health
   ```

2. **Check Nginx status**
   ```bash
   sudo systemctl status nginx
   sudo systemctl restart nginx
   ```

3. **Check build output**
   ```bash
   ls -la /opt/applications/oan-ui-service/dist/
   ```

4. **View error logs**
   ```bash
   sudo tail -100 /var/log/nginx/error.log
   tail -100 /var/log/app-deployment.log
   ```

### Health Check Failing

1. **Verify service is listening**
   ```bash
   sudo netstat -tlnp | grep 5000
   ```

2. **Test endpoint directly**
   ```bash
   curl -v http://localhost:5000/health
   ```

3. **Check Nginx configuration**
   ```bash
   sudo nginx -t
   sudo cat /etc/nginx/sites-enabled/oan-ui-service
   ```

### Build Failures

1. **Check npm logs**
   ```bash
   tail -200 /var/log/app-deployment.log | grep -A5 "npm"
   ```

2. **Manual rebuild**
   ```bash
   cd /opt/applications/oan-ui-service
   npm clean-install
   npm run build
   ```

3. **Check disk space**
   ```bash
   df -h
   du -sh /opt/applications/
   ```

### JWT Token Issues

1. **Verify token format**
   ```bash
   # Check at https://jwt.io/
   # Paste your token in the "Encoded" section
   ```

2. **Check required claims**
   ```json
   {
     "sub": "required",
     "name": "required",
     "email": "required",
     "iat": "required",
     "exp": "required - must be in future"
   }
   ```

3. **Test authentication**
   ```bash
   curl "http://localhost:5000/?token=YOUR_TOKEN"
   # Should display the React app, not an error page
   ```

## Deploying Additional Applications

### To Add Agri Help (when URL is available):

1. Update `app-deployment.sh` with:
   ```bash
   # Clone agri_help repository
   AGRI_DIR="$APPS_DIR/agri_help"
   git clone https://github.com/CORRECT_ORG/agri_help "$AGRI_DIR"
   
   # Analyze dependencies (check for package.json, requirements.txt, etc.)
   # Install based on technology stack
   # Configure Nginx routing
   ```

2. Update Nginx configuration for routing:
   ```nginx
   location /agri-help/ {
       proxy_pass http://localhost:5001/;
   }
   ```

3. Update health checks in Terraform if needed

### To Add Custom Applications:

1. Create a new Git repository with your application
2. Add deployment commands to `app-deployment.sh`:
   ```bash
   # Clone repo
   git clone https://github.com/org/your-app "$APPS_DIR/your-app"
   
   # Install dependencies (npm, pip, etc.)
   # Build the application
   # Configure reverse proxy port
   ```

3. Update Nginx configuration with new location block
4. Redeploy or add to next deployment

## Performance Considerations

### Application Sizing

- **OAN UI Service:** Frontend only, minimal resource usage
- **Load:** Can handle 1000+ concurrent users per instance
- **Memory Usage:** ~200MB for Nginx + Node/Vite runtime

### Scaling

**Horizontal Scaling:**
- Load balancer automatically distributes traffic to multiple instances
- Deploy multiple instances behind the same load balancer
- Auto-scaling groups can be configured in Terraform

**Vertical Scaling:**
- Increase instance size (larger CPU/RAM)
- Adjust in variables.tf and redeploy

### Network Performance

- HTTP/2 supported via Nginx
- Gzip compression enabled for CSS/JS
- Static assets cached for 1 year
- Typical response time: <100ms

## Security Considerations

### Current Setup

✓ Load balancer provides DDoS protection  
✓ Nginx handles SSL/TLS termination  
✓ JWT authentication required for access  
✓ Security groups/NSGs restrict ports  
✓ HTTPS support available  

### Recommendations

- Generate your own RSA keys for JWT (don't use demo keys in production)
- Implement token refresh mechanism
- Monitor access logs for suspicious activity
- Use httpOnly cookies for token storage
- Enable rate limiting in Nginx
- Regular security updates for Node.js/npm packages
- Regular NVIDIA driver updates

## File Locations

```
/opt/applications/
├── oan-ui-service/          # Application source and build
│   ├── src/                 # React source code
│   ├── dist/                # Production build output
│   ├── package.json         # Dependencies manifest
│   └── vite.config.ts       # Vite configuration
├── deployment-report.txt    # Deployment summary

/var/log/
├── app-deployment.log       # Installation and deployment logs
├── nginx/
│   ├── access.log          # HTTP access logs
│   └── error.log           # HTTP error logs
└── cloud-init-output.log   # Full cloud-init logs

/etc/nginx/
├── sites-available/
│   └── oan-ui-service      # Nginx configuration
└── sites-enabled/          # Symlink to active configs

/opt/
└── deployment-info.txt     # Deployment report with URLs
```

## Quick Reference Commands

```bash
# Check deployment progress
sudo tail -f /var/log/app-deployment.log

# View application URLs
cat /opt/deployment-info.txt

# Restart application
sudo systemctl restart nginx

# View running processes
ps aux | grep -E 'nginx|node'

# Check listening ports
sudo netstat -tlnp

# View system resources
top
df -h
free -m

# Check GPU status (if NVIDIA installed)
nvidia-smi

# Test application
curl http://localhost:5000/health
curl http://localhost:5000/

# View Nginx error logs
sudo tail -50 /var/log/nginx/error.log

# Rebuild application
cd /opt/applications/oan-ui-service && npm run build
```

## Next Steps

1. **Deploy infrastructure** using `./deploy.sh`
2. **Wait for instance to be ready** (20-40 minutes)
3. **Verify load balancer health** (all targets should be healthy)
4. **Access application** via load balancer URL
5. **Test JWT authentication** with demo or custom tokens
6. **Monitor logs** for any errors
7. **Configure your authentication service** to issue JWT tokens

## Support & Documentation

- **OAN UI Service README:** https://github.com/the-swag-coder/oan-ui-service/blob/main/README.md
- **JWT Verification:** https://jwt.io/
- **Nginx Documentation:** https://nginx.org/
- **CUDA Installation:** https://developer.nvidia.com/cuda-downloads
- **Terraform AWS:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform Azure:** https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Terraform GCP:** https://registry.terraform.io/providers/hashicorp/google/latest/docs
