output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_http_listener_arn" {
  description = "The ARN of the HTTP listener for the ALB"
  value       = aws_lb_listener.http.arn
}

output "alb_http_target_group_arn" {
  description = "The ARN of the HTTP target group for the ALB"
  value       = aws_lb_target_group.http.arn
}
