# This module (row 4) includes the configuration setup for my VPC, subnets (public & private), IGW and routing info
# The additional rows allow dynamic/flexible collobaration - i.e. colleague may want to use diff sandbox configurations

module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = "10.0.0.0/16"
  vpc_name            = "tm-vpc"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]
}

module "security_group" {
  source  = "./modules/security-group"
  sg_name = "tm-ecs-sg"
  vpc_id  = module.vpc.vpc_id
}

module "alb" {
  source            = "./modules/alb"
  alb_name          = "tm-app-alb"
  security_group_id = module.security_group.security_group_ids
  subnet_ids        = module.vpc.public_subnets
  target_group_name = "tm-target-group"
  target_port       = 3001
  vpc_id            = module.vpc.vpc_id
  certificate_arn   = "arn:aws:acm:us-east-1:713881828888:certificate/be1c87f5-68d8-4ae2-89ea-8caf27640c8c"
}

module "ecs" {
  source             = "./modules/ecs"
  cluster_name       = "tm-ecs-cluster"
  task_family        = "tm-task"
  task_cpu           = "1024"
  task_memory        = "3072"
  container_name     = "tm-container"
  container_image    = "713881828888.dkr.ecr.us-east-1.amazonaws.com/threat-model:latest"
  container_port     = 3001
  service_name       = "my-tm-service"
  desired_count      = 1
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [module.security_group.sg_id]
  target_group_arn   = module.alb.target_group_arn
  listener_http_arn  = module.alb.http_listener
  listener_https_arn = module.alb.https_listener

  create_iam_role    = false
  execution_role_arn = "arn:aws:iam::767398132018:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::767398132018:role/ecsTaskExecutionRole"
  iam_role_name      = "ecsTaskExecutionRole"
}
