# Local Values and Common Tags
# This file defines local values that are computed or derived from variables

locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      ManagedBy     = "terraform"
      Project       = "digital-public-goods"
      TerraformRepo = "multi-cloud-gpu-terraform"
      LastUpdated   = timestamp()
    }
  )

  # Environment-specific naming
  name_prefix = "${var.environment}-${var.vm_name}"
  
  # Resource naming convention
  resource_names = {
    vpc              = "${local.name_prefix}-vpc"
    subnet           = "${local.name_prefix}-subnet"
    security_group   = "${local.name_prefix}-sg"
    instance         = "${local.name_prefix}-instance"
    load_balancer    = "${local.name_prefix}-lb"
    target_group     = "${local.name_prefix}-tg"
    auto_scaling     = "${local.name_prefix}-asg"
  }

  # Network configuration
  network_config = {
    vpc_cidr           = var.vpc_cidr
    public_subnet_cidr = var.public_subnet_cidr
    private_subnet_cidr = try(var.private_subnet_cidr, cidrsubnet(var.vpc_cidr, 8, 2))
  }

  # Cloud-specific configurations
  cloud_configs = {
    aws = {
      instance_type = "g5.4xlarge"
      ami_pattern   = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      ami_owner     = "099720109477"  # Canonical
    }
    azure = {
      vm_size       = "Standard_NV36ads_A10_v5"
      image_publisher = "Canonical"
      image_offer     = "0001-com-ubuntu-server-jammy"
      image_sku       = "22_04-lts-gen2"
    }
    gcp = {
      machine_type  = "n1-standard-4"
      gpu_type      = "nvidia-l4"
      gpu_count     = 1
      image_family  = "ubuntu-2204-lts"
      image_project = "ubuntu-os-cloud"
    }
  }

  # Auto-scaling configuration
  autoscaling_config = var.enable_autoscaling ? {
    min_size         = try(var.min_instances, 1)
    max_size         = try(var.max_instances, 5)
    desired_capacity = var.instance_count
    health_check_type = "ELB"
    health_check_grace_period = 300
  } : null

  # Monitoring configuration
  monitoring_config = var.enable_monitoring ? {
    detailed_monitoring = true
    cloudwatch_enabled  = true
    metrics_granularity = "1Minute"
  } : {
    detailed_monitoring = false
    cloudwatch_enabled  = false
    metrics_granularity = "5Minute"
  }

  # Backup configuration
  backup_config = var.enable_backups ? {
    enabled           = true
    retention_days    = try(var.backup_retention, 7)
    backup_window     = "03:00-04:00"  # 3-4 AM UTC
    maintenance_window = "sun:04:00-sun:05:00"
  } : {
    enabled = false
  }

  # Security configuration
  security_config = {
    enable_ssl             = var.enable_ssl
    allowed_ssh_cidrs      = var.allowed_ssh_cidrs
    enable_waf             = try(var.enable_waf, false)
    enable_vpc_flow_logs   = try(var.enable_vpc_flow_logs, false)
  }

  # Lifecycle policies
  lifecycle_rules = {
    create_before_destroy = true
    prevent_destroy       = var.environment == "production" ? true : false
    ignore_changes        = ["tags.LastUpdated"]
  }
}
