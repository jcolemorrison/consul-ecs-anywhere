provider "aws" {
  region = "us-east-1"
}

## Grab Default VPC
data "aws_vpc" "default" {
  default = true
}

## Use the default subnets
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

## ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "ecs-anywhere-cluster"
}

## - Make the Task Definition for ECS Anywhere

resource "aws_ecs_task_definition" "task" {
  family                = "${var.prefix}-task-definition"
  container_definitions = file("${path.module}/task-definition.tpl.json")

  ## literally not documented lol
  ## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#argument-reference
  requires_compatibilities = ["EXTERNAL"]
}

## - Create the Instance
resource "aws_instance" "instance" {
  ami                    = "ami-0747bdcabd34c712a"
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data = base64encode(templatefile("${path.module}/setup-script.sh", {
    region          = "us-east-1"
    cluster         = "ecs-anywhere-cluster"
    activation_code = aws_ssm_activation.ssm_activation_pair.activation_code
    activation_id   = aws_ssm_activation.ssm_activation_pair.id
  }))
  depends_on = [aws_ssm_activation.ssm_activation_pair]
  key_name   = "ecs_anywhere_us_east_1"
}

## - Create the Security Group and rules
resource "aws_security_group" "instance_sg" {
  name_prefix = "${var.prefix}-instance-sg"
  description = "Firewall for aws instance"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "instance_allow_80" {
  security_group_id = aws_security_group.instance_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow HTTP traffic."
}

resource "aws_security_group_rule" "instance_allow_443" {
  security_group_id = aws_security_group.instance_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow HTTPS traffic."
}

resource "aws_security_group_rule" "instance_allow_22" {
  security_group_id = aws_security_group.instance_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow SSH traffic."
}

resource "aws_security_group_rule" "instance_allow_outbound" {
  security_group_id = aws_security_group.instance_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  description       = "Allow any outbound traffic."
}

## Make ECS Anywhere Role
resource "aws_iam_role" "ecs_anywhere" {
  name               = "${var.prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_anywhere_assume_role_doc.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}

data "aws_iam_policy_document" "ecs_anywhere_assume_role_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_ssm_activation" "ssm_activation_pair" {
  name               = "ssm_activation_pair"
  description        = "ssmActivationPair"
  registration_limit = 3
  iam_role           = aws_iam_role.ecs_anywhere.id
  depends_on         = [aws_iam_role.ecs_anywhere]
}

#### The ECS Task
resource "aws_ecs_service" "task" {
  name            = "${var.prefix}-task"
  cluster         = "ecs-anywhere-cluster"
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 3
  launch_type     = "EXTERNAL"

  placement_constraints {
    type = "distinctInstance"
  }
}