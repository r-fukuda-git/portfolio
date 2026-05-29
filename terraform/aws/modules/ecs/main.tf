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
