output "cluster_id" {
  description = "The ID of the ElastiCache cluster"
  value       = aws_elasticache_cluster.main.id
}

output "primary_endpoint" {
  description = "The primary endpoint of the ElastiCache cluster"
  value       = aws_elasticache_cluster.main.primary_endpoint_address
}

output "primary_endpoint_port" {
  description = "The primary endpoint port of the ElastiCache cluster"
  value       = aws_elasticache_cluster.main.port
}
