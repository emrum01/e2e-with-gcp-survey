terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPCネットワーク
resource "google_compute_network" "vpc" {
  name                    = "survey-vpc-${var.env}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "survey-subnet-${var.env}"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region

  private_ip_google_access = true
}

# Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "survey-db-ip-${var.env}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "instance" {
  name             = "survey-db-${var.env}"
  database_version = "POSTGRES_15"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.instance.name
  password = var.database_password
}

# Cloud Run (Backend)
resource "google_cloud_run_v2_service" "backend" {
  name     = "survey-backend-${var.env}"
  location = var.region

  template {
    containers {
      image = "gcr.io/${var.project_id}/survey-backend:latest"
      
      env {
        name  = "DB_HOST"
        value = google_sql_database_instance.instance.private_ip_address
      }
      env {
        name  = "DB_USER"
        value = var.database_user
      }
      env {
        name  = "DB_PASSWORD"
        value = var.database_password
      }
      env {
        name  = "DB_NAME"
        value = var.database_name
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}

# Cloud Run (Frontend)
resource "google_cloud_run_v2_service" "frontend" {
  name     = "survey-frontend-${var.env}"
  location = var.region

  template {
    containers {
      image = "gcr.io/${var.project_id}/survey-frontend:latest"
      
      env {
        name  = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }
    }
  }
}

# VPCアクセスコネクタ
resource "google_vpc_access_connector" "connector" {
  name          = "survey-vpc-connector-${var.env}"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name
}

# Cloud Build Trigger (Backend)
resource "google_cloudbuild_trigger" "backend" {
  name     = "survey-backend-${var.env}"
  location = var.region

  github {
    owner = "emrum01"
    name  = "e2e-with-gcp-survey"
    push {
      branch = "^main$"
    }
  }

  included_files = ["backend/**"]
  filename       = "backend/cloudbuild.yaml"
}

# Cloud Build Trigger (Frontend)
resource "google_cloudbuild_trigger" "frontend" {
  name     = "survey-frontend-${var.env}"
  location = var.region

  github {
    owner = "emrum01"
    name  = "e2e-with-gcp-survey"
    push {
      branch = "^main$"
    }
  }

  included_files = ["frontend/**"]
  filename       = "frontend/cloudbuild.yaml"
}
