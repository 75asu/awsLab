output "db_cluster_arn" {
  description = "The ARN of the RDS cluster"
  value       = aws_rds_cluster.main.arn
}

output "db_endpoint" {
  description = "The endpoint of the RDS cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "db_port" {
  description = "The port of the RDS cluster"
  value       = aws_rds_cluster.main.port
}
