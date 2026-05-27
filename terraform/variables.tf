variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
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
