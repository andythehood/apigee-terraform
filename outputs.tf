output "apigee_org" {
  value = google_apigee_organization.apigee_org.id
}

output "apigee_service_attachment" {
  value = google_apigee_instance.apigee_instance.service_attachment
}

output "apigee_instance_ip_range" {
  value = google_apigee_instance.apigee_instance.ip_range
}

output "service_networking_peering_cidr_address" {
  value = local.service_networking_peering_cidr_address
}


output "service_networking_peering_cidr_length" {
  value = local.service_networking_peering_cidr_length
}