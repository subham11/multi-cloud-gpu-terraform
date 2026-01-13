# Cloud-Init Script Generation

locals {
  # Bootstrap script that downloads full setup
  nvidia_cuda_init_script = base64encode(<<-EOT
#!/bin/bash
exec > >(tee /var/log/bootstrap.log) 2>&1
cd /root

# Write Git credentials if provided
echo "${var.git_username}" > /tmp/git_username
echo "${var.git_password}" > /tmp/git_password
chmod 600 /tmp/git_username /tmp/git_password

# Embed full setup script
cat > /tmp/full-setup.sh << 'EMBEDDED_SCRIPT'
${file("${path.module}/${var.setup_script_path}")}
EMBEDDED_SCRIPT

chmod +x /tmp/full-setup.sh
bash /tmp/full-setup.sh
EOT
  )
}
