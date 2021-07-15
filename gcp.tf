provider "google" {
  project = var.gcp_project
  region  = "us-west1"
  zone    = "us-west1-c"
}

resource "google_compute_instance" "instance" {
  name         = "${var.prefix}-instance"
  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20210604"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = templatefile("${path.module}/setup-script.sh", {
    region          = "us-east-1"
    cluster         = "ecs-anywhere-cluster"
    activation_code = aws_ssm_activation.ssm_activation_pair.activation_code
    activation_id   = aws_ssm_activation.ssm_activation_pair.id
  })

  tags = ["ecs-anywhere-server"]
}

resource "google_compute_firewall" "instance" {
  name    = "${var.prefix}-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ecs-anywhere-server"]
}