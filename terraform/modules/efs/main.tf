resource "aws_efs_file_system" "prophet_model" {
  creation_token = "${var.project_name}-${var.environment}-prophet-model"
  encrypted      = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-prophet-model"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_efs_mount_target" "prophet_model" {
  for_each        = toset(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.prophet_model.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_prophet.id]
}

resource "aws_security_group" "efs_prophet" {
  name_prefix = "${var.project_name}-${var.environment}-efs-prophet-"
  vpc_id      = var.vpc_id
  description = "Allow NFS from EKS nodes to Prophet EFS"

  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-efs-prophet-sg"
  }
}