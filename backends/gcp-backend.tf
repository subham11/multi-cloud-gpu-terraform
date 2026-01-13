# ============================================================================
# GCP Remote Backend Configuration (Cloud Storage + Object Lock)
# Template backend block (commented). Use terraform init -backend-config.
# ============================================================================

/*
terraform {
  backend "gcs" {
    bucket  = "my-tfstate-bucket"
    prefix  = "multi-cloud-gpu"
    # Optional CMEK
    # encryption_key = "projects/PROJECT_ID/locations/global/keyRings/terraform/cryptoKeys/state"
  }
}
*/

# Setup (run once)
# 1) Create bucket:
#    gsutil mb -p PROJECT_ID -l us-central1 gs://my-tfstate-bucket
# 2) Enable versioning:
#    gsutil versioning set on gs://my-tfstate-bucket
# 3) (Optional) Set default CMEK:
#    gsutil encryption set -k projects/PROJECT_ID/locations/global/keyRings/terraform/cryptoKeys/state gs://my-tfstate-bucket
# 4) Run init with backend config:
#    terraform init -reconfigure -backend-config=backends/gcp-backend.hcl

# Backend config file example (backends/gcp-backend.hcl):
# bucket  = "my-tfstate-bucket"
# prefix  = "multi-cloud-gpu"
# encryption_key = "projects/PROJECT_ID/locations/global/keyRings/terraform/cryptoKeys/state" # optional

# Note: Keep only one active backend configuration when running terraform init.
