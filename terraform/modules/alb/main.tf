## My application load balancer
resource "aws_lb" "tm_app_lb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

## My ALB target group
resource "aws_lb_target_group" "tm_app_lb_tg" {
  name        = var.target_group_name
  target_type = "ip"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
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
  certificate_arn   = var.certificate_arn
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tm_app_lb_tg.arn
  }
}

