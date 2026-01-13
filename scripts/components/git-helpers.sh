#!/bin/bash
# Git Credentials and Clone Helper Component

# Global variables for credentials
GIT_USERNAME=""
GIT_PASSWORD=""

# Load Git credentials from files
load_git_credentials() {
  if [ -f /tmp/git_username ]; then
    GIT_USERNAME=$(cat /tmp/git_username)
    echo "Git username loaded: $GIT_USERNAME"
  fi
  
  if [ -f /tmp/git_password ]; then
    GIT_PASSWORD=$(cat /tmp/git_password)
    echo "Git password loaded: ***"
  fi
}

# Clone repository with fallback authentication
# Usage: clone_repo <repo_url> <target_dir> <repo_name>
clone_repo() {
  local repo_url="$1"
  local target_dir="$2"
  local repo_name="$3"
  
  echo "Attempting to clone $repo_name..."
  
  # Try public clone first
  if git clone "$repo_url" "$target_dir" 2>&1; then
    echo "✓ $repo_name cloned successfully (public access)"
    return 0
  fi
  
  # If failed and credentials available, try with authentication
  if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_PASSWORD" ]; then
    echo "Public access failed. Trying with credentials..."
    
    # Extract repo path from URL
    local repo_path=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|.git$||')
    local auth_url="https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${repo_path}.git"
    
    # Remove failed directory
    rm -rf "$target_dir"
    
    if git clone "$auth_url" "$target_dir" 2>&1; then
      echo "✓ $repo_name cloned successfully (authenticated)"
      return 0
    fi
  fi
  
  echo "✗ Failed to clone $repo_name"
  return 1
}
