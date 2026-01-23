resource "aws_kinesis_stream" "this" {
  name        = var.stream_name
  shard_count = var.shard_count

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${var.stream_name}"
  })
}
