output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_services.ecs_cluster_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS database"
  value       = module.rds.db_endpoint
}

output "elasticache_primary_endpoint" {
  description = "Primary endpoint of the ElastiCache cluster"
  value       = module.elasticache.primary_endpoint
}
