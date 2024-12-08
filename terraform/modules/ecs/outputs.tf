output "ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value       = aws_ecs_cluster.tm_ecs_cluster.id
}

output "ecs_service_id" {
  description = "The ID of the ECS Service"
  value       = aws_ecs_service.tm_app_service.id
}