module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.5//vpc"
  name   = var.product_name

  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

resource "aws_network_acl_rule" "https" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "https_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO CARTOGRAPHY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "cartography" {
  name        = "cartography"
  description = "Allow inbound traffic to cartography load balancer"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow outbound connections to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to neo4j http"
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Access to neo4j https"
    from_port   = 7473
    to_port     = 7473
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Access to neo4j bolt"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Access to neo4j bolt"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    self        = true
  }
}

resource "aws_flow_log" "cartography" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.cartography_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "cartography_flow_log" {
  name              = "cartography_flow_log"
  retention_in_days = 14
}