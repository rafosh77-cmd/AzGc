terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "google" {
  project = "defender-lab"
  region  = "us-central1"
}



resource "random_id" "rand" {
  byte_length = 3
}

resource "google_storage_bucket" "bucket" {
  name                        = "lab-policylab-${random_id.rand.hex}"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = var.labels
}

resource "google_compute_network" "vpc" {
  name                    = "lab-policylab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "lab-policylab-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.self_link
}

# Allow HTTPS only; 0.0.0.0/0 is acceptable here by policy (only 443)
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.name
  allow {
  protocol = "tcp"
  ports    = ["443"]
}
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}
