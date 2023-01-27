resource "aws_rds_cluster" "kf-aurora-cluster-postgre" {
  cluster_identifier = "${var.service_name}-rds-aurora-postgre-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "12.12" # allows zero downtime patching
  database_name      = "${var.service_name}_db_fk"
  master_username    = aws_ssm_parameter.kf-postgresql-master-user.value
  master_password    = aws_ssm_parameter.kf-postgresql-master-password.value
  vpc_security_group_ids = [
    aws_security_group.kf-sg-postgresql.id
  ]
  db_subnet_group_name = aws_db_subnet_group.kf-subnet-postgresql.name

  tags = {
    Name = "${var.service_name}-rds-aurora-postgre-cluster"
  }
}

resource "aws_rds_cluster_instance" "kf-aurora-instance-postgre" {
  identifier          = "${var.service_name}-rds-aurora-instance"
  cluster_identifier  = aws_rds_cluster.kf-aurora-cluster-postgre.id
  engine              = aws_rds_cluster.kf-aurora-cluster-postgre.engine
  engine_version      = aws_rds_cluster.kf-aurora-cluster-postgre.engine_version
  instance_class      = var.rds_instance_type
  publicly_accessible = false

  tags = {
    Name = "${var.service_name}-rds-aurora-instance"
  }
}

resource "random_string" "kf_psql_master_user" {
  length  = 16
  numeric = false
  special = false
}

resource "random_password" "kf_psql_master_pass" {
  length  = 36
  special = true
}

resource "aws_ssm_parameter" "kf-postgresql-master-user" {
  name  = "${var.service_name}_rds_kf_postgresql_master_user"
  type  = "SecureString"
  value = random_string.kf_psql_master_user.result
}

resource "aws_ssm_parameter" "kf-postgresql-master-password" {
  name  = "${var.service_name}_rds_kf_postgresql_master_password"
  type  = "SecureString"
  value = random_password.kf_psql_master_pass.result
}

resource "aws_security_group" "kf-sg-postgresql" {
  name        = "kf-sg-postgresql"
  vpc_id      = aws_vpc.kf-vpc.id
  description = "Aurora RDS SG"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "Only internal VPC access"
  }

  tags = {
    "Name" = "kf-sg-postgresql"
  }
}

resource "aws_db_subnet_group" "kf-subnet-postgresql" {
  name       = "kf-subnet-postgresql"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    "Name" = "kf-subnet-postgresql"
  }
}
