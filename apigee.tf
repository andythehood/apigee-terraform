
locals {
  # FOR EVALUATION, allocate a /28 for management and runtime.
  # For PAID ORGS, allocate a /22 for runtime and a /28 for management.
  # Assumes that service_networking_peering_cidr is a /20 CIDR block.

  #EVAL
  # /28 for runtime
  apigee_runtime_cidr_range = cidrsubnet(var.service_networking_peering_cidr, 8, 0) # 10.21.0.0/28
  apigee_mgmt_cidr_range    = cidrsubnet(var.service_networking_peering_cidr, 8, 1) # 10.21.0.16/28


  #PROD

  # /22 for runtime
  # apigee_runtime_cidr_range = cidrsubnet(var.service_networking_peering_cidr, 2, 0) # 10.21.0.0/22

  # base for /28s (starting from next /22)
  # base_for_mgmt = cidrsubnet(var.service_networking_peering_cidr, 2, 1) # 10.21.4.0/22
  # apigee_mgmt_cidr_range = cidrsubnet(local.base_for_mgmt, 6, 0)      # 10.21.4.0/28
}

output "apigee_runtime_cidr_range" {
  value = local.apigee_runtime_cidr_range
}


output "apigee_mgmt_cidr_range" {
  value = local.apigee_mgmt_cidr_range
}


# Apigee organization
resource "google_apigee_organization" "apigee_org" {
  project_id          = data.google_project.apigee.project_id
  display_name        = "Apigee Organization for ${data.google_project.apigee.project_id}"
  description         = "Apigee Organization created via Terraform for DEV environment"
  analytics_region    = var.region
  disable_vpc_peering = false
  authorized_network  = google_compute_network.nonprod_vpc.id
  runtime_type        = "CLOUD"

  # For testing purposes, we can use EVALUATION billing type
  billing_type = "EVALUATION"
  retention    = "MINIMUM"

  # billing_type = "SUBSCRIPTION"
  # retention = "DELETION_RETENTION_UNSPECIFIED"

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
  name     = "au-sydney-instance"
  location = var.region
  org_id   = google_apigee_organization.apigee_org.id

  # Uncomment the following line to specify a the CIDR ranges, otherwise Apigee will auto allocate from the Service Networking peering range
  # ip_range = "10.21.0.0/28,10.21.0.16/28"
  ip_range = "${local.apigee_runtime_cidr_range},${local.apigee_mgmt_cidr_range}"


}

# Apigee environments and groups
resource "google_apigee_environment" "public_env" {
  name   = "public"
  org_id = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "public_group" {
  name   = "public-group"
  org_id = google_apigee_organization.apigee_org.id
  hostnames = [
    "api.example.com",
    "api-public-dev.ramsayhealth.com.au",
  ]
}

resource "google_apigee_environment" "private_env" {
  name   = "private"
  org_id = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "private_group" {
  name   = "private-group"
  org_id = google_apigee_organization.apigee_org.id
  hostnames = [
    "internal-api.example.com",
    "private.api-dev.ramsayhealth.com.au",
  ]
}


# Eval Orgs only support a maximum of two environments and environment groups

# resource "google_apigee_environment" "partner_env" {
#   name   = "partner"
#   org_id = google_apigee_organization.apigee_org.id
# }

# resource "google_apigee_envgroup" "partner_group" {
#   name      = "partner-group"
#   org_id    = google_apigee_organization.apigee_org.id
#   hostnames = [
#     "internal-api.example.com",
#     "partner.api-public-dev.ramsayhealth.com.au",
#     "partner.api-dev.ramsayhealth.com.au",
#     ]
# }




# Attach environments to environment groups
resource "google_apigee_envgroup_attachment" "attach_public" {
  envgroup_id = google_apigee_envgroup.public_group.id
  environment = google_apigee_environment.public_env.name
}

resource "google_apigee_envgroup_attachment" "attach_private" {
  envgroup_id = google_apigee_envgroup.private_group.id
  environment = google_apigee_environment.private_env.name
}

# resource "google_apigee_envgroup_attachment" "attach_partner" {
#   envgroup_id = google_apigee_envgroup.partner_group.id
#   environment = google_apigee_environment.partner_env.name
# }


# Attach environments to instance
resource "google_apigee_instance_attachment" "attach_public" {
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.public_env.name
}

resource "google_apigee_instance_attachment" "attach_private" {
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.private_env.name

  depends_on = [ google_apigee_instance_attachment.attach_public ]
}

