# # module "eks" {
# #   source  = "terraform-aws-modules/eks/aws"
# #   version = "~> 21.0"

# #   name               = "my-cluster"
# #   kubernetes_version = "1.33"
# #   create_kms_key = false

# #   iam_role_name            = "ethos-cand-${local.candidate_id}-eks-cluster"
# #   iam_role_use_name_prefix = false   # exact name, no random suffix appended
# #   iam_role_tags = {
# #     RoleType = "cluster-control-plane"   # extra tags only for this role
# #   }

# # #   addons = {
# # #     coredns                = {}
# # #     # eks-pod-identity-agent = {
# # #     #   before_compute = true
# # #     # }
# # #     kube-proxy             = {}
# # #     vpc-cni                = {
# # #       before_compute = true
# # #     }
# # #   }

# #   # Optional
# #   endpoint_public_access = true

# #   # Optional: Adds the current caller identity as an administrator via cluster access entry
# #   enable_cluster_creator_admin_permissions = true

# #   vpc_id                   = module.vpc.vpc_id
# #   subnet_ids               = module.vpc.public_subnets
# #   control_plane_subnet_ids = module.vpc.public_subnets

# # #   # EKS Managed Node Group(s)
# # #   eks_managed_node_groups = {
# # #     example = {
# # #       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
# # #       ami_type       = "AL2023_x86_64_STANDARD"
# # #       ami_id = "ami-0ca6eca76c038f7ef"
        
# # #       instance_types = ["t3.medium"]

# # #       min_size     = 2
# # #       max_size     = 2
# # #       desired_size = 2

# # #     }
# # #   }
# # # encryption_config = {
# # #   provider_key_arn = module.kms.key_arn
# # # }
# # encryption_config = null

# #   tags = {
# #     "ethos:project"   = "devops-test"
# #     "ethos:candidate" = "jesus-eduardo85"
# #   }
# # }


# # resource "aws_iam_role" "demo-node" {
# #   name = "ethos-cand-${local.candidate_id}-eks-cluster-node"

# #   assume_role_policy = <<POLICY
# # {
# #   "Version": "2012-10-17",
# #   "Statement": [
# #     {
# #       "Effect": "Allow",
# #       "Principal": {
# #         "Service": "ec2.amazonaws.com"
# #       },
# #       "Action": "sts:AssumeRole"
# #     }
# #   ]
# # }
# # POLICY
# # }

# # resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# #   role       = aws_iam_role.demo-node.name
# # }

# # resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# #   role       = aws_iam_role.demo-node.name
# # }

# # resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# #   role       = aws_iam_role.demo-node.name
# # }

# # resource "aws_eks_node_group" "demo" {
# #   cluster_name    = module.eks.cluster_name
# #   node_group_name = "demo"
# #   node_role_arn   = aws_iam_role.demo-node.arn
# #   subnet_ids      = module.vpc.public_subnets
# #   ami_type = "AL2023_x86_64_STANDARD"

# #   scaling_config {
# #     desired_size = 1
# #     max_size     = 1
# #     min_size     = 1
# #   }

# #   tags = local.common_tags

# #   depends_on = [
# #     aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
# #     aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
# #     aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
# #   ]
# # }

# # # module "kms" {
# # #   source  = "terraform-aws-modules/kms/aws"
# # #   version = "~> 2.0"

# # #   description = "KMS key for ethos candidate test"
  
# # #   # Key options
# # #   deletion_window_in_days = 7
# # #   enable_key_rotation     = true

# # #   # Aliases
# # #   aliases = ["ethos-cand-jesus-eduardo85-key"]

# # #   tags = {
# # #     "ethos:candidate" = "jesus-eduardo85"
# # #     "ethos:project"   = "devops-test"
# # #   }
# # # }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 21.0"

#   name               = "my-cluster"
#   kubernetes_version = "1.33"
#   create_kms_key     = false

#   iam_role_name            = "ethos-cand-${local.candidate_id}-eks-cluster"
#   iam_role_use_name_prefix = false

#   # iam_role_tags is ADDITIVE on top of var.tags.
#   # Remove it entirely — var.tags below already covers all resources.
#   # Only keep it if you need EXTRA tags on that role specifically:
#   # iam_role_tags = { RoleType = "cluster-control-plane" }

#   endpoint_public_access                   = true
#   enable_cluster_creator_admin_permissions = true

#   vpc_id                   = module.vpc.vpc_id
#   subnet_ids               = module.vpc.public_subnets
#   control_plane_subnet_ids = module.vpc.public_subnets

#   encryption_config = null

#   # ✅ This single variable propagates to ALL subcomponents the module manages:
#   # the EKS cluster, IAM role, security groups, CloudWatch log group,
#   # node groups created via eks_managed_node_groups, KMS key, etc.
#   tags = local.common_tags
# }