# resource "aws_eks_cluster" "example" {
#   name = "example"

#   access_config {
#     authentication_mode = "API"
#   }

#   role_arn = aws_iam_role.cluster.arn
#   version  = "1.35"

#   vpc_config {
#     subnet_ids = module.vpc.public_subnets
#     endpoint_private_access = true
#   }

#   # Ensure that IAM Role permissions are created before and deleted
#   # after EKS Cluster handling. Otherwise, EKS will not be able to
#   # properly delete EKS managed EC2 infrastructure such as Security Groups.
#   depends_on = [
#     aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
#   ]
# }

# resource "aws_iam_role" "cluster" {
#   name = "ethos-cand-${local.candidate_id}-eks-cluster"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sts:AssumeRole",
#           "sts:TagSession"
#         ]
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.cluster.name
# }


# resource "aws_iam_role" "demo-node" {
#   name = "ethos-cand-${local.candidate_id}-eks-cluster-node"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.demo-node.name
# }

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.demo-node.name
# }

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.demo-node.name
# }

# resource "aws_eks_node_group" "demo" {
#   cluster_name    = aws_eks_cluster.example.name
#   node_group_name = "demo"
#   node_role_arn   = aws_iam_role.demo-node.arn
#   subnet_ids      = module.vpc.public_subnets
#   ami_type = "AL2023_x86_64_STANDARD"

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }