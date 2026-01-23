resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # For ECS Task Execution
}

# Policy to allow tasks to read secrets
resource "aws_iam_policy" "ecs_secrets_access" {
  name        = "${var.project_name}-${var.environment}-ecs-secrets-access"
  description = "Allows ECS tasks to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ],
        Resource = [
          var.rds_password_secret_arn # Allow access to RDS password secret
        ]
      },
    ],
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-secrets-access"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_access.arn
}


resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-task"
  container_definitions    = jsonencode([
    {
      name      = var.project_name,
      image     = var.container_image,
      cpu       = var.container_cpu,
      memory    = var.container_memory,
      essential = true,
      portMappings = [
        {
          containerPort = var.container_port,
          hostPort      = var.container_port
        }
      ],
      environment = [
        {
          name  = "RDS_ENDPOINT",
          value = var.rds_endpoint
        },
        {
          name  = "RDS_PORT",
          value = var.rds_port
        },
        {
          name  = "RDS_DB_NAME",
          value = var.rds_db_name
        },
        {
          name  = "RDS_USERNAME",
          value = var.rds_username
        },
        {
          name  = "ELASTICACHE_ENDPOINT",
          value = var.elasticache_endpoint
        },
        {
          name  = "ELASTICACHE_PORT",
          value = var.elasticache_port
        }
      ],
      secrets = [ # Pass RDS password as a secret to the container
        {
          name      = "RDS_PASSWORD",
          valueFrom = var.rds_password_secret_arn
        }
      ]
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Use the same role for task and execution
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-task"
  })
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.project_name
    container_port   = var.container_port
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-service"
  })
  
  lifecycle {
    ignore_changes = [desired_count] # Allow autoscaling to manage desired count
  }
}
