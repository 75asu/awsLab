output "solana_node_cpu_alarm_arn" {
  description = "The ARN of the Solana node CPU alarm"
  value       = module.monitoring.solana_node_cpu_alarm_arn
}

output "kinesis_iterator_age_alarm_arn" {
  description = "The ARN of the Kinesis iterator age alarm"
  value       = module.monitoring.kinesis_iterator_age_alarm_arn
}
