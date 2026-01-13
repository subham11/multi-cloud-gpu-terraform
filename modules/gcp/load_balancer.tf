# GCP Load Balancer Configuration

# Health Check
resource "google_compute_health_check" "http" {
  count               = 1
  name                = "${var.vm_name}-health-check"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 5000
    request_path = "/health"
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  count                 = 1
  name                  = "${var.vm_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.http[0].id]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  session_affinity      = "NONE"

  backend {
    group           = google_compute_instance_group_manager.gpu[0].instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = false
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  count           = 1
  name            = "${var.vm_name}-url-map"
  default_service = google_compute_backend_service.default[0].id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "default" {
  count   = 1
  name    = "${var.vm_name}-http-proxy"
  url_map = google_compute_url_map.default[0].id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "http" {
  count                 = 1
  name                  = "${var.vm_name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.default[0].id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
