# GCP Instance Template and Managed Instance Group

resource "google_compute_instance_template" "gpu" {
  count                   = 1
  name_prefix             = "${var.vm_name}-template-"
  machine_type            = var.machine_type
  region                  = var.region
  metadata_startup_script = base64decode(var.user_data_script)

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork         = values(google_compute_subnetwork.private)[0].self_link
    stack_type         = "IPV4_ONLY"
    queue_count        = 0
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  tags = ["gpu-instance", "http-server", "https-server", "app-backend"]

  labels = var.labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "gpu" {
  count              = 1
  name               = "${var.vm_name}-mig"
  base_instance_name = var.vm_name
  zone               = "${var.region}-a"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.gpu[0].id
  }

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }
}
