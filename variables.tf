variable "apigee_project_id" {
  description = "The ID of the Apigee project"
  type        = string
  default     = "aviato-andy-apigee-tf-fk"
  # default     = "prj-wrk-eiip-apigw-org-dev-zj" # Uncomment if using a different project ID
}

variable "hub_project_id" {
  description = "The ID of the Hub Host project"
  type        = string
  default     = "aviato-andy-apigee-tf-fk"
  # default     = "prj-wrk-eiip-apigw-org-dev-zj" # Uncomment if using a different project ID
}

variable "region" {
  description = "Region for resources"
  type        = string
  default     = "australia-southeast1"
}
