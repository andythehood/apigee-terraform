
# Apigee organization
resource "google_apigee_organization" "apigee_org" {
  project_id          = data.google_project.apigee.project_id
  display_name        = "Apigee Organization for ${data.google_project.apigee.project_id}"
  description         = "Apigee Organization created via Terraform for DEV environment"
  analytics_region    = var.region
  disable_vpc_peering = false
  authorized_network  = google_compute_network.custom_vpc.id
  runtime_type        = "CLOUD"
  #   subscription_type = "SUBSCRIPTION"
  billing_type = "EVALUATION"
  retention    = "MINIMUM"

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_service_networking_connection.apigee_private_connection,
    google_project_service.apigee
  ]
}

# Apigee instance
resource "google_apigee_instance" "apigee_instance" {
  name               = "au-sydney-instance"
  location           = var.region
  org_id             = google_apigee_organization.apigee_org.id
  peering_cidr_range = "SLASH_22"

    lifecycle {
    prevent_destroy = true
  }
}

# Apigee environments
resource "google_apigee_environment" "public_env" {
  name   = "public"
  org_id = google_apigee_organization.apigee_org.id
}

resource "google_apigee_environment" "private_env" {
  name   = "private"
  org_id = google_apigee_organization.apigee_org.id
}

# Apigee environment groups
resource "google_apigee_envgroup" "public_group" {
  name      = "public-group"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = ["api.example.com"]
}

resource "google_apigee_envgroup" "private_group" {
  name      = "private-group"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = ["internal-api.example.com"]
}

# Attach environments to environment groups
resource "google_apigee_envgroup_attachment" "attach_public" {
  envgroup_id = google_apigee_envgroup.public_group.id
  environment = google_apigee_environment.public_env.name
}

resource "google_apigee_envgroup_attachment" "attach_private" {
  envgroup_id = google_apigee_envgroup.private_group.id
  environment = google_apigee_environment.private_env.name
}


