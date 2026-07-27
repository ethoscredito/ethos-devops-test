locals {
  app_name = "ethos-cand-${var.candidate_id}"

  tags = {
    "ethos:candidate" = var.candidate_id
    "ethos:project"   = "devops-test"
    ManagedBy         = "Terraform"
  }
}
