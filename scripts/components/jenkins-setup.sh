#!/bin/bash
# Jenkins CI/CD Installation and Configuration Component

install_jenkins() {
  local log_file="${1:-/var/log/jenkins-setup.log}"
  
  echo "Starting Jenkins CI/CD installation..." | tee -a "$log_file"
  
  # Install Java (Jenkins requirement)
  echo "Installing Java 17..." | tee -a "$log_file"
  apt-get install -y openjdk-17-jdk >> "$log_file" 2>&1
  echo "Java installed: $(java -version 2>&1 | head -1)" | tee -a "$log_file"
  
  # Add Jenkins repository
  echo "Adding Jenkins repository..." | tee -a "$log_file"
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | \
    tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  apt-get update >> "$log_file" 2>&1
  
  # Install Jenkins
  echo "Installing Jenkins..." | tee -a "$log_file"
  apt-get install -y jenkins >> "$log_file" 2>&1
  
  # Configure Jenkins to skip setup wizard
  JENKINS_HOME="/var/lib/jenkins"
  mkdir -p "$JENKINS_HOME/init.groovy.d"
  
  cat > "$JENKINS_HOME/init.groovy.d/01-setup.groovy" << 'GROOVY'
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println "Admin user created: admin/admin123"
GROOVY
  
  chown -R jenkins:jenkins "$JENKINS_HOME/init.groovy.d"
  
  # Start Jenkins
  systemctl start jenkins
  systemctl enable jenkins
  
  # Wait for Jenkins to be ready
  echo "Waiting for Jenkins to start..." | tee -a "$log_file"
  local max_wait=60
  local wait_count=0
  while [ $wait_count -lt $max_wait ]; do
    if curl -sf http://localhost:8080/login > /dev/null 2>&1; then
      echo "✓ Jenkins is ready!" | tee -a "$log_file"
      break
    fi
    sleep 5
    ((wait_count++))
  done
  
  if [ $wait_count -eq $max_wait ]; then
    echo "⚠ Jenkins may not be fully ready yet" | tee -a "$log_file"
  fi
  
  # Save credentials
  cat > /opt/jenkins-credentials.txt << CREDS
Jenkins URL: http://localhost:8080
Username: admin
Password: admin123

Change password after login:
Manage Jenkins → Manage Users → admin → Configure → Password
CREDS
  chmod 600 /opt/jenkins-credentials.txt
  
  echo "✓ Jenkins installation completed" | tee -a "$log_file"
}
