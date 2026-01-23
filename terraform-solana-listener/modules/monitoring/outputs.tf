output "solana_node_cpu_alarm_arn" {
  description = "The ARN of the Solana node CPU alarm"
  value       = aws_cloudwatch_metric_alarm.solana_node_cpu.arn
}

output "kinesis_iterator_age_alarm_arn" {
  description = "The ARN of the Kinesis iterator age alarm"
  value       = aws_cloudwatch_metric_alarm.kinesis_iterator_age.arn
}
