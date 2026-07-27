locals {
  candidate_id = "jesus-eduardo85"
  github_repo = "ethos-devops-test"
  github_org = "ethoscredito"

  common_tags = {
    "ethos:project"   = "devops-test"
    "ethos:candidate" = "jesus-eduardo85"
  }
}

# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"

#   name = "ethos-cand-${local.candidate_id}-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
#   # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

#   enable_nat_gateway   = false
#   single_nat_gateway   = false
#   enable_vpn_gateway   = false
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   create_database_subnet_group           = false
#   create_database_subnet_route_table     = false
#   create_database_internet_gateway_route = false

#   manage_default_network_acl    = false
#   manage_default_security_group = false
#   manage_default_route_table    = false

#   # public_subnet_tags = {
#   #   "kubernetes.io/role/elb" = 1
#   # }

#   # private_subnet_tags = {
#   #   "kubernetes.io/role/internal-elb" = 1
#   # }

#   tags                     = local.common_tags
#   vpc_tags                 = local.common_tags
#   # private_subnet_tags      = merge(local.common_tags, { "kubernetes.io/role/elb" = 1})
#   public_subnet_tags       = merge(local.common_tags, { "kubernetes.io/role/elb" = 1})
#   igw_tags                 = local.common_tags
#   nat_gateway_tags         = local.common_tags
#   nat_eip_tags             = local.common_tags
#   private_route_table_tags = local.common_tags
#   public_route_table_tags  = local.common_tags

#   use_ipam_pool = false
# }

# locals {
#   candidate_id = "jesus-eduardo85"
#   common_tags = {
#     "ethos:candidate" = "jesus-eduardo85"
#     "ethos:project"   = "devops-test"
#     Terraform         = "true"
#   }
# }

# # VPC
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   enable_dns_support   = true
#   tags = merge(local.common_tags, { Name = "ethos-cand-${local.candidate_id}-vpc" })
# }

# # Internet Gateway
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
#   tags   = merge(local.common_tags, { Name = "ethos-cand-${local.candidate_id}-igw" })
# }

# # Public Subnets
# resource "aws_subnet" "public_a" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"

#   # No merge, raw tags
#   tags = {
#     "ethos:candidate" = "jesus-eduardo85"
#     "ethos:project"   = "devops-test"
#     # Name              = "test-subnet"
#   }
# }

# # resource "aws_subnet" "public_b" {
# #   vpc_id                  = aws_vpc.main.id
# #   cidr_block              = "10.0.2.0/24"
# #   availability_zone       = "us-east-1b"
# #   map_public_ip_on_launch = true
# #   tags = merge(local.common_tags, { Name = "ethos-cand-${local.candidate_id}-public-b" })
# # }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#   tags   = merge(local.common_tags, { Name = "ethos-cand-${local.candidate_id}-rt-public" })
# }

# resource "aws_route" "public_internet" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.main.id
# }

# resource "aws_route_table_association" "public_a" {
#   subnet_id      = aws_subnet.public_a.id
#   route_table_id = aws_route_table.public.id
# }

# # resource "aws_route_table_association" "public_b" {
# #   subnet_id      = aws_subnet.public_b.id
# #   route_table_id = aws_route_table.public.id
# # }

# output "public_subnet" {
#   value = aws_subnet.public_a
# }