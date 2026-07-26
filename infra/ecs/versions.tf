terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Backend local a propósito: el usuario IAM del candidato está acotado por
  # permissions boundary y no tiene permisos de S3/DynamoDB para un backend
  # remoto. El state NO se versiona (ver .gitignore). Para un entorno real
  # se usaría backend "s3" con bloqueo en DynamoDB — documentado en
  # docs/ARCHITECTURE.md.
}
