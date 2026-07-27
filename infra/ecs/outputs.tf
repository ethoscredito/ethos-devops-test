output "ecr_repository" {
  value = local.ecr_repository
}

output "ecr_url" {
  value = local.ecr_url
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
