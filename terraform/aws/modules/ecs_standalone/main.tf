locals {
  service_image = var.ecr_repository_url != "" ? "${var.ecr_repository_url}:${var.service_image_tag}" : ""
}

resource "aws_ecs_task_definition" "standalone" {
  family                   = "${var.project_name}-${var.env}-standalone-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.standalone_task_cpu
  memory                   = var.standalone_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.env}-standalone-container"
      image     = var.standalone_image != "" ? var.standalone_image : local.service_image
      essential = true
      command   = var.standalone_command
    }
  ])
}

data "aws_iam_policy_document" "events_assume" {
  count = var.standalone_schedule_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events_ecs" {
  count              = var.standalone_schedule_enabled ? 1 : 0
  name               = "${var.project_name}-${var.env}-events-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume[0].json

  tags = {
    Name = "${var.project_name}-${var.env}-events-ecs-role"
  }
}

data "aws_iam_policy_document" "events_run_task" {
  count = var.standalone_schedule_enabled ? 1 : 0

  statement {
    sid    = "RunStandaloneTask"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
    ]
    resources = [
      aws_ecs_task_definition.standalone.arn,
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [var.cluster_arn]
    }
  }

  statement {
    sid    = "PassExecutionRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      var.execution_role_arn,
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "events_ecs" {
  count  = var.standalone_schedule_enabled ? 1 : 0
  name   = "${var.project_name}-${var.env}-events-ecs-policy"
  role   = aws_iam_role.events_ecs[0].id
  policy = data.aws_iam_policy_document.events_run_task[0].json
}

resource "aws_cloudwatch_event_rule" "standalone" {
  count               = var.standalone_schedule_enabled ? 1 : 0
  name                = "${var.project_name}-${var.env}-standalone-schedule"
  description         = "Run standalone ECS task on a schedule"
  schedule_expression = var.standalone_schedule_expression
}

resource "aws_cloudwatch_event_target" "standalone" {
  count     = var.standalone_schedule_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.standalone[0].name
  target_id = "standalone-ecs-task"
  arn       = var.cluster_arn
  role_arn  = aws_iam_role.events_ecs[0].arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.standalone.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = false
    }
  }
}
