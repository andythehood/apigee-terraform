# ----------------------------------------------------
# Self-signed SSL certificate (local)
# ----------------------------------------------------
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "aviato.consulting"
    organization = "Aviato Consulting"
  }
  dns_names = [
    "internal.example.com",
    "api.internal.example.com",
    "api-public-dev.ramsayhealth.com.au",
    "partner.api-public-dev.ramsayhealth.com.au",
    "partner.api-dev.ramsayhealth.com.au",
    "private.api-dev.ramsayhealth.com.au",
  ]

  validity_period_hours = 8760
  is_ca_certificate     = false

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# resource "google_compute_region_ssl_certificate" "self_signed" {
#   name        = "apigee-internal-alb-cert"
#   private_key = tls_private_key.private_key.private_key_pem
#   certificate = tls_self_signed_cert.cert.cert_pem

#   depends_on = [
#     google_project_service.compute
#   ]
# }


# resource "google_certificate_manager_certificate" "host_self_managed_cert" {
#   project  = "aviato-andy-sandbox-host"
#   name     = "apigee-internal-alb-cert"
#   location = var.region
#   self_managed {
#     pem_certificate = tls_self_signed_cert.cert.cert_pem
#     pem_private_key = tls_private_key.private_key.private_key_pem
#   }

#   depends_on = [
#     google_project_service.certificatemanager
#   ]
#   #   self_managed {
#   #   pem_certificate = file("test-fixtures/cert.pem")
#   #   pem_private_key = file("test-fixtures/private-key.pem")                                                                                                                
#   # }
# }

resource "google_certificate_manager_certificate" "self_managed_cert" {
  name     = "apigee-internal-alb-cert"
  location = var.region
  self_managed {
    pem_certificate = tls_self_signed_cert.cert.cert_pem
    pem_private_key = tls_private_key.private_key.private_key_pem
  }
  depends_on = [
    google_project_service.certificatemanager
  ]
  #   self_managed {
  #   pem_certificate = file("test-fixtures/cert.pem")
  #   pem_private_key = file("test-fixtures/private-key.pem")                                                                                                                
  # }
}

# ----------------------------------------------------
# PSC NEG backend
# ----------------------------------------------------
resource "google_compute_region_network_endpoint_group" "psc_neg" {
  name                  = "apigee-psc-neg"
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  region                = var.region
  network               = google_compute_network.nonprod_vpc.self_link
  subnetwork            = google_compute_subnetwork.nonprod_vpc_apigee_subnet.self_link
  psc_target_service    = google_apigee_instance.apigee_instance.service_attachment
}


# ----------------------------------------------------
# Backend service
# ----------------------------------------------------
resource "google_compute_region_backend_service" "https_backend" {
  name                  = "apigee-internal-alb-backend"
  protocol              = "HTTPS"
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.psc_neg.id
  }

  #   health_checks = [google_compute_health_check.default.self_link]
}

# resource "google_compute_health_check" "default" {
#   name                = "psc-health-check"
#   check_interval_sec  = 10
#   timeout_sec         = 5
#   healthy_threshold   = 2
#   unhealthy_threshold = 3

#   https_health_check {
#     port         = 443
#     request_path = "/"
#   }
# }

# ----------------------------------------------------
# URL map and target HTTPS proxy
# ----------------------------------------------------
resource "google_compute_region_url_map" "url_map" {
  name            = "apigee-internal-alb"
  region          = var.region
  default_service = google_compute_region_backend_service.https_backend.id
}

resource "google_compute_region_target_https_proxy" "proxy" {
  # count   = var.environment == "dev" ? 1 : 0
  name    = "apigee-internal-alb-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.url_map.self_link

  # ssl_certificates = [google_compute_region_ssl_certificate.self_signed.id]
  certificate_manager_certificates = ["projects/${var.apigee_project_id}/locations/${var.region}/certificates/apigee-internal-alb-cert"]
  # certificate_manager_certificates = [google_certificate_manager_certificate.self_managed_cert.id]
  # certificate_manager_certificates = [google_certificate_manager_certificate.host_self_managed_cert.id]
}

# resource "google_compute_region_target_https_proxy" "proxy" {
#   count                = var.environment == "dev" ? 1 : 0
#   name    = "apigee-internal-alb-proxy"
#   region  = var.region
#   url_map = google_compute_region_url_map.url_map.self_link

#   # ssl_certificates = [google_compute_region_ssl_certificate.self_signed.id]
#   # certificate_manager_certificates = [google_certificate_manager_certificate.self_managed_cert.id]
#   certificate_manager_certificates = [google_certificate_manager_certificate.host_self_managed_cert.id]
# }

# ----------------------------------------------------
# Static Internal IP address
# ----------------------------------------------------
resource "google_compute_address" "ip_address" {
  name         = "apigee-internal-alb-ip"
  subnetwork   = google_compute_subnetwork.nonprod_vpc_apigee_subnet.self_link
  address_type = "INTERNAL"
  region       = var.region
}


# ----------------------------------------------------
# Forwarding rule (HTTPS, internal)
# ----------------------------------------------------
resource "google_compute_forwarding_rule" "forwarding_rule" {
  name                  = "apigee-internal-alb-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.proxy.id
  network               = google_compute_network.nonprod_vpc.self_link
  subnetwork            = google_compute_subnetwork.nonprod_vpc_apigee_subnet.self_link
  ip_address            = google_compute_address.ip_address.address
  ip_protocol           = "TCP"
  region                = var.region

  depends_on = [google_compute_subnetwork.nonprod_vpc_proxy_only_subnet]
}
