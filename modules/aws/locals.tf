# AWS Local Variables and Configuration

locals {
  # Region preference order: Mumbai > Chennai > us-east-1
  supported_regions = ["ap-south-1", "ap-south-2", "us-east-1"]

  # Determine effective region - use specified region if supported, otherwise default to Mumbai
  effective_region = (
    contains(local.supported_regions, var.region)
    ? var.region
    : "ap-south-1" # Default to Mumbai
  )

  # AMI mapping for Ubuntu 22.04 LTS by region
  ami_by_region = {
    "ap-south-1" = "ami-0c55b159cbfafe1f0" # Mumbai
    "ap-south-2" = "ami-0f7a4a9a7b5e7c5d1" # Chennai
    "us-east-1"  = "ami-0b5eea76982371e91" # US East 1
  }

  selected_ami = local.ami_by_region[local.effective_region]
}
