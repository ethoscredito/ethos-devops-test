locals {
  ecr_repository = "ethos-cand-${var.candidate_id}"
  ecr_url        = "816583873447.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repository}"
}
