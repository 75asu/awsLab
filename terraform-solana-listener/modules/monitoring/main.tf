# Alarm for high CPU utilization on Solana RPC nodes
resource "aws_cloudwatch_metric_alarm" "solana_node_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-solana-node-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric alarms when the CPU utilization of the Solana RPC nodes is high."
  
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = [] # Add SNS topic ARN here in a real scenario
  ok_actions      = []

  tags = var.tags
}

# Alarm for Kinesis stream iterator age
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${var.project_name}-${var.environment}-kinesis-high-iterator-age"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000" # 10 seconds
  alarm_description   = "This metric alarms when the Kinesis consumer is falling behind."

  dimensions = {
    StreamName = var.kinesis_stream_name
  }

  alarm_actions = [] # Add SNS topic ARN here in a real scenario
  ok_actions      = []

  tags = var.tags
}
