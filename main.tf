terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
  required_version = ">= 1.3.0"
}


provider "google" {
  project = var.apigee_project_id
  region  = var.region

}

# Data source: Reference existing project
data "google_project" "apigee" {
  project_id = var.apigee_project_id
}


# Data source: Reference existing project
data "google_project" "hub" {
  project_id = var.hub_project_id
}



# Enable Compute Engine API
resource "google_project_service" "compute" {
  project            = data.google_project.apigee.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable Apigee API
resource "google_project_service" "apigee" {
  project            = data.google_project.apigee.project_id
  service            = "apigee.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud KMS API
resource "google_project_service" "cloudkms" {
  project            = data.google_project.apigee.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# Enable Service Networking API
resource "google_project_service" "servicenetworking" {
  project            = data.google_project.apigee.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud DNS API
resource "google_project_service" "cloud_dns" {
  project            = data.google_project.apigee.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

