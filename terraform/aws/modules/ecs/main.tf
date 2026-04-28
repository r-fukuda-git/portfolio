# クラスターの作成
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

# タスク定義の作成
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.env}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  # コンテナからAPIを叩く権限付与
  execution_role_arn = var.execution_role_arn

  # コンテナの定義
  container_definitions = jsondecode([
    {
      name      = "${var.project_name}-${var.env}-ecs-container"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.containerPort
          hostPort      = var.hostPort
        }
      ]
    }
  ])
}

# サービス定義の作成
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.env}-service"
  cluster         = aws_ecs_cluster.this
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count // 常に起動するコンテナの数
  launch_type     = FARGATE

  network_configuration {
    subnets          = var.subnets.ids
    security_groups  = var.security_groups_ids
    assign_public_ip = true
  }
}
