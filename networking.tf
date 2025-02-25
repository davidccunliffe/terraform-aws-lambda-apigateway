module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}-${var.environment}-vpc"

  create_igw         = false
  enable_nat_gateway = false

  cidr = var.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 1)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]


}

# Add endpoints to VPC for Systems Manager and Secrets Manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id = module.vpc.vpc_id

  service_name = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [aws_security_group.ssm_sg.id]
  subnet_ids         = module.vpc.private_subnets
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id = module.vpc.vpc_id

  service_name = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [aws_security_group.ssm_sg.id]
  subnet_ids         = module.vpc.private_subnets
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id = module.vpc.vpc_id

  service_name = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [aws_security_group.ssm_sg.id]
  subnet_ids         = module.vpc.private_subnets
}

# Create a security group for the endpoint
resource "aws_security_group" "ssm_sg" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an API Gateway VPC Endpoint for Private API Gateway
resource "aws_vpc_endpoint" "apigw" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.apigw_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

# API Gateway Security Group
resource "aws_security_group" "apigw_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}