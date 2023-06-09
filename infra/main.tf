## Create ECR repo
resource "aws_ecr_repository" "python-demo" {
  name = "python-demo" # ECR repo name
}

## ECR access policy
data "aws_iam_policy_document" "ecr-policy" {
  statement {
    sid    = "ecr policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.aws_acc_id]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
  }
}

## Attach ECR policy to repository
resource "aws_ecr_repository_policy" "python-demo-policy" {
  repository = aws_ecr_repository.python-demo.name
  policy     = data.aws_iam_policy_document.ecr-policy.json
}

## Create ACS production cluster
resource "aws_ecs_cluster" "production" {
  name = "production" # Naming the cluster
}

### Create ACS development cluster
#resource "aws_ecs_cluster" "development" {
#  name = "development"
#}

## Get availability zones
data "aws_availability_zones" "available_zones" {
  state = "available"
}

## Create VPC
resource "aws_vpc" "default" {
  cidr_block = "10.32.0.0/16"
}

## Create Public subnet
resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = true
}

## Create private subnet
resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.default.id
}

## Create IGW
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
}

## Route table for internet access
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

## Create elastic IP
resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

## Create NAT GW
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

## Route table for privat4e subnets to go to internet
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

## Security group for ALB
resource "aws_security_group" "lb" {
  name        = "example-alb-security-group"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Create ALB
resource "aws_lb" "ecs-prod-lb" {
  name            = "ecs-prod-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}


resource "aws_lb_target_group" "ecs-prod-target-group" {
  name        = "ecs-prod-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "python_demo" {
  load_balancer_arn = aws_lb.ecs-prod-lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs-prod-target-group.id
    type             = "forward"
  }
}