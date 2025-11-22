############################################
# Security Group - API Gateway (Público)
############################################
resource "aws_security_group" "api_gateway_sg" {
  name        = "stockwiz-${var.environment}-api-gateway-sg"
  description = "SG publico para API Gateway"
  vpc_id      = var.vpc_id

  # Inbound: Permitir HTTP desde Internet
  ingress {
    description = "HTTP publico"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # público
  }

  # Outbound: permitido a todos
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# SG para Servicios Internos (Product / Inventory)
############################################
resource "aws_security_group" "internal_services_sg" {
  name        = "stockwiz-${var.environment}-internal-services-sg"
  description = "SG para servicios internos (no expuestos)"
  vpc_id      = var.vpc_id

  # Inbound desde API Gateway SG
  ingress {
    description      = "Permitir acceso desde API Gateway"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    security_groups  = [aws_security_group.api_gateway_sg.id]
  }

  # Outbound permitido a todos
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
