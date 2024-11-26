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

  enable_deletion_protection = true

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
  certificate_arn   = "arn:aws:acm:us-east-1:713881828888:certificate/64027502-eda2-46d4-9c35-c668be8e4c34"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tm_app_lb_tg.arn
  }
}





