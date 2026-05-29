data "aws_region" "current" {}

locals {
  service_image          = "${var.ecr_repository_url}:${var.service_image_tag}"
  service_log_group      = "/ecs/${var.project_name}-${var.env}-service"
  service_container_name = "${var.project_name}-${var.env}-service-container"
}

# クラスター
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.env}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name = "${var.project_name}-${var.env}-ecs-cluster"
  }
}

# ---------------------------------------------------------------------------
# Pattern A: 常駐 ECS Service + ALB
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "service" {
  name              = local.service_log_group
  retention_in_days = var.service_log_retention_in_days

  tags = {
    Name = "${var.project_name}-${var.env}-service"
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.project_name}-${var.env}-service-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.service_task_cpu
  memory                   = var.service_task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = local.service_container_name
      image     = local.service_image
      essential = true
      environment = [
        {
          name  = "PORT"
          value = tostring(var.service_container_port)
        }
      ]
      portMappings = [
        {
          containerPort = var.service_container_port
          hostPort      = var.service_host_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.service]
}

resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_ids
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.env}-alb"
  }
}

resource "aws_lb_target_group" "service" {
  name        = "${var.project_name}-${var.env}-tg"
  port        = var.service_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.env}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.env}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = local.service_container_name
    container_port   = var.service_container_port
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    # 初回 apply は 0 台。以降の台数は main-cd の UpdateService に任せ、apply で 0 に戻さない
    ignore_changes = [desired_count]
  }
}

# ---------------------------------------------------------------------------
# Pattern B: Standalone ECS Task（手動 run-task / 任意スケジュール）
# ---------------------------------------------------------------------------

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
      values   = [aws_ecs_cluster.this.arn]
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
  arn       = aws_ecs_cluster.this.arn
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
