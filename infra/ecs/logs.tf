resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${local.app_name}"

  tags = local.tags
}
