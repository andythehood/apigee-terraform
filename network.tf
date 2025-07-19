# VPC network resource
resource "google_compute_network" "nonprod_vpc" {
  name                    = "nonprod-vpc"
  auto_create_subnetworks = false
  project                 = data.google_project.hub.project_id
  depends_on              = [google_project_service.compute, google_project_service.apigee]
}

# Subnet resource
resource "google_compute_subnetwork" "nonprod_vpc_apigee_subnet" {
  name          = "nonprod-vpc-apigee-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.nonprod_vpc.id
  project       = data.google_project.hub.project_id
}

resource "google_compute_subnetwork" "nonprod_vpc_host_subnet" {
  name          = "nonprod-vpc-host-subnet"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.nonprod_vpc.id
  project       = data.google_project.hub.project_id
}

resource "google_compute_route" "override_route_0" {
  name        = "default-internet-route-override-0"
  dest_range  = "0.0.0.0/1"
  network     = google_compute_network.nonprod_vpc.name
  next_hop_ip = "10.10.1.1"

  priority    = 100

  depends_on = [ google_compute_subnetwork.nonprod_vpc_host_subnet ]
}

resource "google_compute_route" "override_route_1" {
  name        = "default-internet-route-override-1"
  dest_range  = "128.0.0.0/1"
  network     = google_compute_network.nonprod_vpc.name
  next_hop_ip = "10.10.1.1"
  priority    = 100

  depends_on = [ google_compute_subnetwork.nonprod_vpc_host_subnet ]

}




# proxy-only subnet
resource "google_compute_subnetwork" "nonprod_vpc_proxy_only_subnet" {
  name          = "nonprod-vpc-proxy-only-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.nonprod_vpc.id
  project       = data.google_project.hub.project_id
}


# Reserve IP range for service networking
resource "google_compute_global_address" "apigee_service_networking_peering_range" {
  name          = "apigee-service-networking-peering-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.21.0.0"
  prefix_length = 20
  network       = google_compute_network.nonprod_vpc.id
  project       = data.google_project.hub.project_id

  depends_on = [google_compute_network.nonprod_vpc]
}

# service networking peering connection
resource "google_service_networking_connection" "apigee_private_connection" {
  network                 = google_compute_network.nonprod_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.apigee_service_networking_peering_range.name]
  

  depends_on = [
    google_project_service.servicenetworking
  ]
}

# Export custom routes
resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering = google_service_networking_connection.apigee_private_connection.peering
  network = google_compute_network.nonprod_vpc.name

  import_custom_routes = false
  export_custom_routes = true
}

