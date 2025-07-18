# Apigee Terraform Infrastructure

This directory contains Terraform configuration files for provisioning and managing Apigee X infrastructure on Google Cloud Platform (GCP).

## Structure

- **main.tf**: Provider configuration, project data sources, and enabling required Google Cloud APIs.
- **variables.tf**: Input variables for project IDs and region.
- **network.tf**: VPC, subnets, proxy subnet, and service networking peering setup.
- **apigee.tf**: Apigee organization, instance, environments, environment groups, and attachments.
- **lb.tf**: Internal HTTPS load balancer, SSL certificate, backend, and forwarding rule for Apigee.
- **dns.tf**: Private DNS zone, DNS records, and DNS peering for Apigee.

## Resources Managed

- **Apigee Organization**: Creates and configures an Apigee organization linked to your GCP project and VPC.
- **Apigee Instance**: Provisions an Apigee instance in the specified region.
- **Apigee Environments**: Sets up logical environments (e.g., `public`, `private`) for API proxies.
- **Environment Groups**: Groups environments and assigns hostnames for routing.
- **Environment Group Attachments**: Attaches environments to their respective groups.
- **VPC and Subnets**: Custom VPC, subnets, and proxy-only subnet for Apigee and load balancer.
- **Service Networking**: Peering and reserved IP ranges for Apigee Private Service Connect.
- **Internal Load Balancer**: HTTPS load balancer for internal Apigee traffic.
- **DNS**: Private DNS zone and records for internal API resolution.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Sufficient permissions to create Apigee resources and manage networking

## Usage

1. **Initialize Terraform:**

```
    terraform init
```

2. **Review the planned changes:**
```
    terraform plan
```
3. **Apply the configuration:**

```
    terraform apply
```
4. **Destroy resources (if needed):**

```
    terraform destroy
```

## Variables

- `apigee_project_id`: The GCP project ID for Apigee resources.
- `hub_project_id`: The GCP project ID for the host VPC.
- `region`: The GCP region for Apigee analytics and instance deployment.

## Notes

- The configuration uses `prevent_destroy` in lifecycle blocks to protect critical resources from accidental deletion.
- Ensure your VPC and networking prerequisites are met before applying.
- Update hostnames and environment names as needed for your organization.

## License

See the root [LICENSE](./LICENSE)
