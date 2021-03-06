###
# The task execution role grants the Amazon ECS container and Fargate agents 
# permission to make AWS API calls on your behalf
###
locals {
  asset_inventory_admin_role       = "AssetInventoryCartographyRole"
  asset_inventory_managed_accounts = split("\n", chomp(replace(file("../configs/accounts.txt"), "\"", "")))
  trusted_role_arns = [
    for account in local.asset_inventory_managed_accounts : "arn:aws:iam::${account}:role/AssetInventorySecurityAuditRole"
  ]
}
resource "aws_iam_role" "task_execution_role" {
  name               = local.asset_inventory_admin_role
  assume_role_policy = data.aws_iam_policy_document.task_execution_role.json
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/Lambda"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "container_registery_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role_policy_attachment" "cartography_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.cartography_policies.arn
}

data "aws_iam_policy_document" "cartography_policies" {
  statement {

    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]
    resources = local.trusted_role_arns
  }

  statement {

    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      "*"
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.neo4j_auth.arn,
      aws_ssm_parameter.neo4j_password.arn,
      aws_ssm_parameter.elasticsearch_user.arn,
      aws_ssm_parameter.elasticsearch_password.arn,
      aws_ssm_parameter.asset_inventory_account_list.arn,
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::packages.*.amazonaws.com/*",
      "arn:aws:s3:::repo.*.amazonaws.com/*"
    ]
  }
}

resource "aws_iam_policy" "cartography_policies" {
  name   = "CartographyTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.cartography_policies.json
}
