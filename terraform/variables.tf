variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro   "
}

variable "instance_name" {
  type    = string
  default = "demo-vault-tf-sentinel"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "owner" {
  type    = string
  default = "dabs"
}

variable "vault_aws_role" {
  description = "Vault AWS secrets engine role that mints dynamic IAM creds"
  type        = string
  default     = "demo-builder"
}

variable "vault_addr" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass Vault settings as Terraform variables"
  type        = string
  default     = ""
}

variable "vault_namespace" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass Vault settings as Terraform variables"
  type        = string
  default     = ""
}

variable "vault_token" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass Vault settings as Terraform variables"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hcp_client_id" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass legacy HCP settings as Terraform variables"
  type        = string
  default     = ""
}

variable "hcp_client_secret" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass legacy HCP settings as Terraform variables"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hcp_project_id" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass legacy HCP settings as Terraform variables"
  type        = string
  default     = ""
}

variable "hcp_packer_bucket" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass legacy HCP Packer settings as Terraform variables"
  type        = string
  default     = ""
}

variable "hcp_packer_channel" {
  description = "Compatibility variable for HCP Terraform workspaces that still pass legacy HCP Packer settings as Terraform variables"
  type        = string
  default     = ""
}
