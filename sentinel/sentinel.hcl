# =============================================================================
# Sentinel policy set — consumed by HCP Terraform.
# In HCP Terraform UI: Settings → Policy Sets → Connect a new policy set
#   • VCS provider: GitHub
#   • Repository:   <your-user>/demo-terraform-vault-sentinel-ec2
#   • Policies path: sentinel
#   • Scope: workspaces in project 'dabs-demos'
# =============================================================================

policy "restrict-instance-type" {
  source            = "./restrict-instance-type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-tags" {
  source            = "./require-tags.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "restrict-region" {
  source            = "./restrict-region.sentinel"
  enforcement_level = "advisory"
}
