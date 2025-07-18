resource "google_dns_managed_zone" "aws_zone" {
  name        = "private-aws-zone"
  dns_name    = "apisvc-prod.ramsayhealth-aws.com.au."
  description = "Example private DNS zone"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.custom_vpc.id
    }
  }

  depends_on = [
    google_project_service.cloud_dns
  ]
}

resource "google_dns_record_set" "a" {
  name         = "svc01.${google_dns_managed_zone.aws_zone.dns_name}"
  managed_zone = google_dns_managed_zone.aws_zone.name
  type         = "A"
  ttl          = 300

  rrdatas = ["10.1.2.3"]
}


resource "google_service_networking_peered_dns_domain" "apigee" {
  name       = "apigee-dns-peering"
  network    = google_compute_network.custom_vpc.name
  dns_suffix = google_dns_managed_zone.aws_zone.dns_name
}
