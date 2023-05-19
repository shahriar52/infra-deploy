## ECS task defination
resource "aws_ecs_task_definition" "python_demo_task" {
  family                   = "python_demo_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

  container_definitions    = <<DEFINITION
  [
    {
      "name": "python_demo_task",
      "image": "${var.container_image}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
DEFINITION
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_ecs_cluster" "ecs-production" {
  cluster_name = var.ecs_production_cluster
}

data "aws_lb_target_group" "lb_tg" {
  name = var.lb_tg_name
}


resource "aws_security_group" "python_demo_task" {
  name        = "python_demo_task-security-group"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    protocol        = "tcp"
    from_port       = 5000
    to_port         = 5000
    security_groups = [var.security_group_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ECS service defination
resource "aws_ecs_service" "python_demo_service" {
  name            = "python_demo_service"
  cluster         = data.aws_ecs_cluster.ecs-production.id
  task_definition = aws_ecs_task_definition.python_demo_task.arn
  desired_count   = var.container_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.python_demo_task.id]
    subnets         = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = data.aws_lb_target_group.lb_tg.id
    container_name   = "python_demo_task"
    container_port   = 5000
  }
}