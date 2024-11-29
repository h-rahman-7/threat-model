## My ECS cluster
resource "aws_ecs_cluster" "tm_ecs_cluster" {
  name = "tm-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

## My application load balancer
resource "aws_lb" "tm_app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tm_sg.id]
  subnets            = [aws_subnet.tm_public_sn1.id,aws_subnet.tm_public_sn2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

## My ALB target group
resource "aws_lb_target_group" "tm_app_lb_tg" {
  name        = "tm-app-lb-tg"
  target_type = "ip"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.tm_vpc.id
}

## My ALB listener for HTTP redirecting to port 443
resource "aws_lb_listener" "tm_http_listener" {
  load_balancer_arn = aws_lb.tm_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.tm_app_lb_tg.arn
  # }  
  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

}


## My ALB listener for HTTPS forwarding to port 3001
resource "aws_lb_listener" "tm_https_listener" {
  load_balancer_arn = aws_lb.tm_app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:713881828888:certificate/be1c87f5-68d8-4ae2-89ea-8caf27640c8c"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tm_app_lb_tg.arn
  }
}

## My ECS task definition
resource "aws_ecs_task_definition" "tm_app_td" {
  family                   = "tm-app-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "1024"
  memory                   = "3072"

  container_definitions = jsonencode([
    {
      name      = "tm-container"
      image     = "713881828888.dkr.ecr.us-east-1.amazonaws.com/threat-model:latest"
      cpu       = 0
      essential = true
      portMappings = [{
        containerPort = 3001
        hostPort      = 3001
        protocol      = "tcp"
      }]
    }
  ])
}

## My ECS service
resource "aws_ecs_service" "tm_app_service" {
  name            = "my-tm-service"
  cluster         = aws_ecs_cluster.tm_ecs_cluster.id
  task_definition = aws_ecs_task_definition.tm_app_td.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.tm_public_sn1.id, aws_subnet.tm_public_sn2.id]
    security_groups  = [aws_security_group.tm_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tm_app_lb_tg.arn
    container_name   = "tm-container"
    container_port   = 3001
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [aws_lb_listener.tm_http_listener]
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = data.aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}




