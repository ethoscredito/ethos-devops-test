resource "aws_ecr_repository" "app" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  # Escaneo de vulnerabilidades en cada push (plus: escaneo de imagen).
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = local.ecr_repository_name
  }
}

# Higiene y costo: solo se conservan las últimas imágenes trazables y las
# untagged se van rápido.
resource "aws_ecr_lifecycle_policy" "app" {
  count      = var.enable_ecr_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Borrar imágenes sin tag después de 3 días"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 3
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Conservar solo las últimas 15 imágenes etiquetadas"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-", "candidato-"]
          countType     = "imageCountMoreThan"
          countNumber   = 15
        }
        action = { type = "expire" }
      }
    ]
  })
}
