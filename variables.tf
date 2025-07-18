variable "apigee_project_id" {
  description = "The ID of the Apigee project"
  type        = string
  default     = "aviato-andy-apigee-tf-fk"
  # default     = "prj-wrk-eiip-apigw-org-dev-zj" 
}

variable "hub_project_id" {
  description = "The ID of the Hub Host project"
  type        = string
  default     = "aviato-andy-apigee-tf-fk"
  # default     = "prj-core-net-hub-d4s3" 
}

variable "region" {
  description = "Region for resources"
  type        = string
  default     = "australia-southeast1"
}
