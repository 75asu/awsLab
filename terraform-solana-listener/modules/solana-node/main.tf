# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-${var.environment}-solana-rpc-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-solana-rpc"
  })
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-${var.environment}-solana-rpc-asg"
  desired_capacity    = var.instance_count
  max_size            = var.instance_count
  min_size            = var.instance_count
  vpc_zone_identifier = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-solana-rpc"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
