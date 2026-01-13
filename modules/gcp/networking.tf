# GCP VPC, Subnets, Router, and NAT

resource "google_compute_network" "vpc" {
  name                    = "${var.vm_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "Custom VPC for ${var.vm_name}"
}

resource "google_compute_subnetwork" "public" {
  for_each      = var.public_subnets
  name          = "${var.vm_name}-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  role          = "ACTIVE"
  private_ip_google_access = true
  enable_flow_logs         = var.enable_flow_logs
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "private" {
  for_each                 = var.private_subnets
  name                     = "${var.vm_name}-${each.key}"
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  enable_flow_logs         = var.enable_flow_logs
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "database" {
  for_each                 = var.enable_database_subnet ? var.database_subnets : {}
  name                     = "${var.vm_name}-${each.key}"
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  enable_flow_logs         = var.enable_flow_logs
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_router" "router" {
  name    = "${var.vm_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vm_name}-nat"
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.private
    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

# Optional private DNS zone
resource "google_dns_managed_zone" "private" {
  count       = var.enable_private_dns_zone ? 1 : 0
  name        = "${var.vm_name}-private-dns"
  dns_name    = "${var.private_dns_zone_name}."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}
