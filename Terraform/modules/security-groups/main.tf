resource "aws_security_group" "security_group" {
  name   = var.sg_name
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"      = var.sg_name,
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }
}
