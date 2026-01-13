# Backend Configuration Templates

Use the templates in this folder to configure a remote backend per cloud. Keep only one active backend when running `terraform init`.

## Quick Use
1) Copy or edit a backend config file (HCL):
   - AWS: backends/aws-backend.hcl
   - Azure: backends/azure-backend.hcl
   - GCP: backends/gcp-backend.hcl
2) Run init with single click (see script below) or manually:
   ```bash
   terraform init -reconfigure -backend-config=backends/aws-backend.hcl
   ```

## Single-Click Init Script
Use `scripts/single_click_init.sh` to be prompted for provider, backend values, and instance name, then run `terraform init` for you.

## Templates
- [aws-backend.tf](aws-backend.tf) – S3 + DynamoDB lock (template block commented)
- [azure-backend.tf](azure-backend.tf) – Blob Storage + lease lock (template block commented)
- [gcp-backend.tf](gcp-backend.tf) – Cloud Storage + object lock (template block commented)
