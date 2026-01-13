#!/bin/bash
# NVIDIA Driver and CUDA Installation Component

install_nvidia_drivers() {
  echo "Detecting NVIDIA GPU..."
  
  if ! lspci | grep -i nvidia > /dev/null; then
    echo "No NVIDIA GPU detected. Skipping driver installation."
    return 0
  fi
  
  echo "NVIDIA GPU detected. Installing drivers and CUDA..."
  
  # Add NVIDIA repository
  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
  dpkg -i /tmp/cuda-keyring.deb
  apt-get update
  
  # Install NVIDIA drivers and CUDA toolkit
  apt-get install -y cuda-toolkit-12-4 nvidia-driver-550
  
  # Add CUDA to PATH
  echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /etc/profile
  echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /etc/profile
  
  # Verify installation
  if nvidia-smi > /dev/null 2>&1; then
    echo "✓ NVIDIA drivers and CUDA installed successfully"
    nvidia-smi
  else
    echo "⚠ NVIDIA drivers installed but nvidia-smi not responding (may need reboot)"
  fi
}
