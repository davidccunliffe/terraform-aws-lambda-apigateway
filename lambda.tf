# Lambda Function in VPC
resource "aws_lambda_function" "hello_lambda" {
  function_name = "hello-world-private"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.9"
  handler       = "main.lambda_handler"
  timeout       = 10

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_code.key

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# Updated Lambda Security Group to only allow API Gateway
resource "aws_security_group" "lambda_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow API Gateway requests from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-security-group"
  }
}

# Allow API Gateway to Invoke Lambda (Even for Anonymous Users)
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowPrivateAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.private_api.execution_arn}/*/*"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_private_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach policy for VPC Access
resource "aws_iam_policy_attachment" "lambda_vpc_access" {
  name       = "lambda_vpc_access_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Upload Lambda function package
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "my-lambda-private-bucket-${random_id.suffix.hex}"
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda_package.zip"
  source = "lambda_package.zip"
}

resource "random_id" "suffix" {
  byte_length = 4
}
