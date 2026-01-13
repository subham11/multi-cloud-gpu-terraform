# GCP Firewall Rules

resource "google_compute_firewall" "http" {
  count   = 1
  name    = "${var.vm_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "https" {
  count   = 1
  name    = "${var.vm_name}-allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "app_ports" {
  count   = 1
  name    = "${var.vm_name}-allow-app-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5000", "3000", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "health_check" {
  count   = 1
  name    = "${var.vm_name}-allow-health-check"
  network = "default"

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP health check ranges
  target_tags   = ["http-server"]
}
