# Fix Required for main.tf

## Issue
The main.tf file has leftover bash script content between the `locals` block and the `aws_instance` resource.

## Current State (BROKEN)
```hcl
# Line 183-196: locals block (CORRECT)
locals {
  nvidia_cuda_init_script = base64encode(<<-EOT
#!/bin/bash
exec > >(tee /var/log/bootstrap.log) 2>&1
cd /root
wget -q https://raw.githubusercontent.com/your-repo/multi-cloud-gpu-terraform/main/scripts/full-setup.sh -O /tmp/full-setup.sh 2>/dev/null || \
cat > /tmp/full-setup.sh << 'EMBEDDED_SCRIPT'
${file("${path.module}/scripts/full-setup.sh")}
EMBEDDED_SCRIPT
chmod +x /tmp/full-setup.sh
bash /tmp/full-setup.sh
EOT
  )
}

# Line 197-609: LEFTOVER BASH CODE (DELETE THIS)
apt-get upgrade -y
# Install build dependencies
apt-get install -y build-essential curl wget git nginx net-tools
...
[400+ lines of bash script]
...

# Line 610+: aws_instance resource (CORRECT)
# GPU Instance
resource "aws_instance" "gpu" {
  count                  = var.cloud_provider == "aws" ? 1 : 0
  ami                    = local.selected_ami
  ...
```

## Required Fix

**DELETE lines 197 through 609** (all bash script content between locals block and aws_instance resource)

## Target State (CORRECT)
```hcl
# Line 183-196: locals block
locals {
  nvidia_cuda_init_script = base64encode(<<-EOT
#!/bin/bash
exec > >(tee /var/log/bootstrap.log) 2>&1
cd /root
wget -q https://raw.githubusercontent.com/your-repo/multi-cloud-gpu-terraform/main/scripts/full-setup.sh -O /tmp/full-setup.sh 2>/dev/null || \
cat > /tmp/full-setup.sh << 'EMBEDDED_SCRIPT'
${file("${path.module}/scripts/full-setup.sh")}
EMBEDDED_SCRIPT
chmod +x /tmp/full-setup.sh
bash /tmp/full-setup.sh
EOT
  )
}

# Line 197: Directly followed by GPU Instance resource
# GPU Instance
resource "aws_instance" "gpu" {
  count                  = var.cloud_provider == "aws" ? 1 : 0
  ami                    = local.selected_ami
  instance_type          = "g5.4xlarge"
  subnet_id              = aws_subnet.public_a[0].id
  vpc_security_group_ids = [aws_security_group.instance[0].id]
  user_data              = local.nvidia_cuda_init_script

  tags = {
    Name = var.vm_name
  }
}
```

## How to Fix

### Option 1: Manual Edit
1. Open main.tf
2. Find line 196 (end of locals block with `}`)
3. Find line 610 (`# GPU Instance`)
4. Delete everything between them (lines 197-609)
5. Save

### Option 2: Search and Replace
Search for:
```
}
apt-get upgrade -y
```

Replace with:
```
}

# GPU Instance
```

Then manually remove any remaining bash content before the `resource "aws_instance" "gpu"` line.

### Option 3: Use a Clean Version
If you have a backup or git history:
```bash
# Restore the locals block to just have the bootstrap script
# All the NVIDIA, Node.js, Jenkins setup is in scripts/full-setup.sh
```

## Verification

After fixing, run:
```bash
terraform fmt
terraform validate
```

Both should succeed with no errors.

## Why This Happened

During the refactoring to create the single-click deployment, we:
1. ✅ Created scripts/full-setup.sh with all bash code (correct)
2. ✅ Modified locals block to use the new bootstrap approach (correct)
3. ❌ Failed to fully remove the old embedded bash script (error)

The old 400+ line embedded bash script should have been completely removed since it's now in scripts/full-setup.sh.

## Files Status

| File | Status |
|------|--------|
| scripts/full-setup.sh | ✅ Complete (650+ lines) |
| QUICK_START.md | ✅ Complete (300+ lines) |
| SINGLE_CLICK_IMPLEMENTATION.md | ✅ Complete (summary) |
| main.tf | ⚠️ Needs cleanup (delete lines 197-609) |
| deploy.sh | ✅ Working (enhanced with single-click messaging) |

## After Fix

Once main.tf is fixed:

1. ✅ `terraform validate` will pass
2. ✅ `terraform apply` will work
3. ✅ Instances will boot and run scripts/full-setup.sh
4. ✅ Everything will be configured automatically
5. ✅ True single-click deployment achieved!
