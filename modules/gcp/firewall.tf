# GCP Firewall Rules

resource "google_compute_firewall" "http" {
  count   = 1
  name    = "${var.vm_name}-allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "https" {
  count   = 1
  name    = "${var.vm_name}-allow-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "app_ports" {
  count   = 1
  name    = "${var.vm_name}-allow-app-ports"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5000", "3000"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Google LB/health ranges
  target_tags   = ["app-backend"]
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "ssh" {
  count   = 1
  name    = "${var.vm_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["gpu-instance"]
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "health_check" {
  count   = 1
  name    = "${var.vm_name}-allow-health-check"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "egress_all" {
  count   = 1
  name    = "${var.vm_name}-egress-all"
  network = google_compute_network.vpc.id

  direction = "EGRESS"
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
