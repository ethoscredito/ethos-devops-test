provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  # Todos los recursos nacen etiquetados. El permissions boundary del candidato
  # exige estos tags en las llamadas Create*, así que se aplican a nivel de
  # provider para no depender de que cada recurso los repita.
  default_tags {
    tags = {
      "ethos:candidate" = var.candidate_id
      "ethos:project"   = var.project_tag
      "ManagedBy"       = "terraform"
      "Path"            = "A-ECS-Fargate"
    }
  }
}
