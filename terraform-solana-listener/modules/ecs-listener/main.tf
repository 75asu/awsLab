# IAM Role for the ECS Task
resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-${var.environment}-ecs-listener-task-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "kinesis_policy" {
  name        = "${var.project_name}-${var.environment}-ecs-listener-kinesis-policy"
  description = "Policy to allow ECS task to read from Kinesis stream"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = [
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards"
        ],
        Effect   = "Allow",
        Resource = var.kinesis_stream_arn
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "kinesis_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.kinesis_policy.arn
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-listener-cluster"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-listener-cluster"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.environment}-listener-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_role.arn # Re-using for simplicity, in prod this would be a separate role

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-listener",
      image     = var.container_image,
      cpu       = var.container_cpu,
      memory    = var.container_memory,
      essential = true,
      portMappings = [],
      environment = [
        {
          name  = "KINESIS_STREAM_ARN",
          value = var.kinesis_stream_arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-listener",
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-listener-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
  }

  depends_on = [aws_iam_role_policy_attachment.kinesis_attachment]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-listener-service"
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.project_name}-${var.environment}-listener"

  tags = var.tags
}
