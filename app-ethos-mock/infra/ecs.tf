# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

#   tags = local.common_tags
# }


# resource "aws_iam_role" "github_actions" {
#   name = "ethos-cand-${local.candidate_id}-git-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.github.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringLike = {
#           "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo}:*"
#         }
#         StringEquals = {
#           "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#         }
#       }
#     }]
#   })

#   tags = local.common_tags
# }

# resource "aws_iam_role_policy" "github_actions" {
#   name = "ecs-express-deploy"
#   role = aws_iam_role.github_actions.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       # ECR — authenticate, push, pull
#       {
#         Effect   = "Allow"
#         Action   = ["ecr:GetAuthorizationToken"]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:InitiateLayerUpload",
#           "ecr:UploadLayerPart",
#           "ecr:CompleteLayerUpload",
#           "ecr:PutImage"
#         ]
#         Resource = aws_ecr_repository.app.arn
#       },
#       # ECS Express Mode — update the service image
#       {
#         Effect = "Allow"
#         Action = [
#           "ecs:UpdateExpressGatewayService",
#           "ecs:DescribeExpressGatewayService",
#           "ecs:ListExpressGatewayServices"
#         ]
#         Resource = "*"
#       },
#       # Required to pass roles to ECS during update
#       {
#         Effect = "Allow"
#         Action = ["iam:PassRole"]
#         Resource = [
#           aws_iam_role.task_execution.arn,
#           aws_iam_role.infrastructure.arn
#         ]
#       }
#     ]
#   })
# }


# resource "aws_ecr_repository" "app" {
#   name                 = "ethos-cand-jesus-eduardo85-repo"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   tags = local.common_tags
# }

# resource "aws_ecr_lifecycle_policy" "app" {
#   repository = aws_ecr_repository.app.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 10 tagged images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["main", "v"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 10
#         }
#         action = { type = "expire" }
#       },
#       {
#         rulePriority = 2
#         description  = "Delete untagged images older than 7 days"
#         selection = {
#           tagStatus   = "untagged"
#           countType   = "sinceImagePushed"
#           countUnit   = "days"
#           countNumber = 7
#         }
#         action = { type = "expire" }
#       }
#     ]
#   })
# }


# resource "aws_iam_role" "infrastructure" {
#   name = "ethos-cand-${local.candidate_id}-infra-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ecs.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })

#   tags = local.common_tags
# }

# resource "aws_iam_role_policy_attachment" "infrastructure_express" {
#   role       = aws_iam_role.infrastructure.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
# }


# resource "aws_iam_role" "task_execution" {
#   name = "ethos-cand-${local.candidate_id}-exec-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "ecs-tasks.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })

#   tags = local.common_tags
# }

# resource "aws_iam_role_policy_attachment" "task_execution_default" {
#   role       = aws_iam_role.task_execution.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# # If your app pulls images from a private ECR, add this too:
# resource "aws_iam_role_policy" "task_execution_ecr" {
#   name = "ecr-pull"
#   role = aws_iam_role.task_execution.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "ecr:GetAuthorizationToken",
#         "ecr:BatchCheckLayerAvailability",
#         "ecr:GetDownloadUrlForLayer",
#         "ecr:BatchGetImage"
#       ]
#       Resource = "*"
#     }]
#   })
# }