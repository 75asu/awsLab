resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-rds-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-subnet-group"
  })
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-rds-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4" # Latest stable version at the time
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = data.aws_secretsmanager_secret_version.db_password.secret_string
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true # For dev environments
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.db_security_group_id]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-cluster"
  })
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1 # Single instance for dev
  identifier         = "${var.project_name}-${var.environment}-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  instance_class     = var.db_instance_class
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-instance-${count.index}"
  })
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}
