# Network Layer Provisioning Guide

Terraform steps to provision secure, scalable, and repeatable network infrastructure across environments before compute.

## 🎯 Scope
- VPC/VNet/VPC Network creation with CIDR controls
- Multi-AZ/zone public, private, and database subnets
- Internet Gateway / NAT Gateway / Cloud NAT for egress
- Route tables/UDRs bound to subnets
- Security Groups / NSGs / Firewall rules with least privilege
- Optional private DNS zones linked to the VPC/VNet
- Flow logs enabled for monitoring and compliance

## 🗂️ State Strategy (Network-First)
- Use a **dedicated workspace or backend key** for the network layer to decouple from compute.
- Recommended workspace name: `network-<env>` (e.g., `network-dev`, `network-prod`).
- For S3 backend: set `key = "network/terraform.tfstate"` (similar for Azure Blob or GCS).

```bash
# Initialize backend for network layer (example AWS S3 backend already defined in backend.tf)
terraform init -reconfigure

# Select or create workspace per environment
terraform workspace select network-dev || terraform workspace new network-dev

# Preview and apply network changes
terraform plan -var-file="terraform.tfvars.dev" -out=network-dev.tfplan
terraform apply "network-dev.tfplan"
```

## ✅ Acceptance Criteria Mapping
- **VPC/VNet created with CIDR**: `aws_vpc.main`, `azurerm_virtual_network.main`, `google_compute_network.vpc`
- **Public/private subnets multi-AZ**: `aws_subnet.public|private|database`, Azure/GCP subnet maps
- **Internet + NAT Gateways**: `aws_internet_gateway.main`, `aws_nat_gateway.main`, `azurerm_nat_gateway.main`, `google_compute_router_nat.nat`
- **Route tables/UDRs**: public/private route tables with associations for each tier
- **Least-privilege SG/NSG/firewall**: SSH restricted via `allowed_ssh_cidrs`, app ports limited to LB/health ranges
- **VPC peering/VPN**: placeholder—add per org needs
- **DNS/private zones**: optional private DNS (Azure `enable_private_dns_zone`, GCP `enable_private_dns_zone`; AWS already supports private hosted zone variable)
- **Flow logs**: AWS VPC Flow Logs, Azure NSG flow logs, GCP subnet flow logs
- **Remote state**: backend.tf provides S3/Azure Blob/GCS options
- **Plan/validate**: `terraform plan` before `apply`
- **Tagging**: common tags/labels applied across resources

## 🌐 Provider-Specific Notes
### AWS
- Subnet maps cover two AZs by default; extend maps for more AZs.
- NAT gateways deployed per public subnet when `enable_nat_gateway = true`.
- Flow logs shipped to CloudWatch with retention controls.
- SSH/Jenkins restricted via `allowed_ssh_cidrs` (set per env).
- Optional Route53 private hosted zone (existing variable `enable_private_hosted_zone`).

### Azure
- VNet CIDR configurable; public/private/database subnets mapped by zone.
- Standard NAT Gateway + route tables for outbound from private subnets.
- NSG rules limit app ports to `AzureLoadBalancer`; SSH restricted via `allowed_ssh_cidrs`.
- NSG flow logs enabled to Storage Account via Network Watcher.
- Optional private DNS zone (`enable_private_dns_zone`, `private_dns_zone_name`).

### GCP
- Custom VPC with separate public/private/database subnets; flow logs enabled on subnets.
- Cloud Router + Cloud NAT provides egress for private workloads.
- Firewall rules tightened (HTTP/HTTPS from internet; app ports from Google LB ranges; SSH allowlist).
- Optional private DNS zone using `google_dns_managed_zone` when `enable_private_dns_zone` is true.

## 🚦 Recommended Workflow
1. **Prepare backend**: uncomment/configure remote backend in `backend.tf` (S3/Blob/GCS) and run `terraform init -reconfigure`.
2. **Select workspace**: `terraform workspace select network-prod || terraform workspace new network-prod`.
3. **Configure variables**: use `terraform.tfvars.<env>` or custom tfvars for CIDRs and `allowed_ssh_cidrs`.
4. **Preview**: `terraform plan -var-file="terraform.tfvars.prod" -out=network-prod.tfplan`.
5. **Apply**: `terraform apply "network-prod.tfplan"`.
6. **Validate**: `terraform state list` and ensure flow logs and routes are in place.
7. **Hand off to compute**: once network is applied, run compute layer (same repo) using a separate workspace/key (e.g., `compute-prod`).

## 🔐 Security Checklist
- Set `allowed_ssh_cidrs` per environment (no 0.0.0.0/0 in prod).
- Keep NAT gateways in private tiers; no public IPs on private workloads (GCP instance template removes public IP).
- Enable flow logs (default true across providers).
- Use private DNS for internal service discovery when needed.
- Tag/label all resources for ownership and cost.

## 🧪 Validation Commands
```bash
# Verify subnets per tier
terraform state list | grep subnet

# Check flow logs resources
terraform state list | grep flow_log

# Confirm NAT gateways
terraform state list | grep nat
```

## 📎 Peering / VPN (Add-On)
- AWS: add `aws_vpc_peering_connection` or `aws_vpn_gateway` + `aws_vpn_connection` per environment.
- Azure: add `azurerm_virtual_network_peering` or `azurerm_vpn_gateway`.
- GCP: add `google_compute_network_peering` or `google_compute_vpn_gateway`/`cloud_router` with tunnels.

## 🧭 Next Steps
- Integrate CI/CD to run `terraform plan` on PRs for the network workspace.
- Add policy-as-code checks (OPA/Sentinel) for CIDR overlap and open ingress.
- Extend to multi-region by duplicating subnet maps and NAT per region.
