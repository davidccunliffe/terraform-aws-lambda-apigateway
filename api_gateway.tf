# Private API Gateway (REST API v1)
resource "aws_api_gateway_rest_api" "private_api" {
  name        = "private-api"
  description = "Private API Gateway that allows anonymous access"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.apigw.id]
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "private_api_root" {
  rest_api_id = aws_api_gateway_rest_api.private_api.id
  parent_id   = aws_api_gateway_rest_api.private_api.root_resource_id
  path_part   = "root"
}

# API Gateway Method
resource "aws_api_gateway_method" "private_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.private_api.id
  resource_id   = aws_api_gateway_resource.private_api_root.id
  http_method   = "GET"
  authorization = "NONE" # Allow anonymous access
}

# API Gateway Integration with Lambda
resource "aws_api_gateway_integration" "private_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.private_api.id
  resource_id             = aws_api_gateway_resource.private_api_root.id
  http_method             = aws_api_gateway_method.private_api_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}

# Deployment of API Gateway
resource "aws_api_gateway_deployment" "private_api_deployment" {
  depends_on  = [aws_api_gateway_integration.private_api_integration]
  rest_api_id = aws_api_gateway_rest_api.private_api.id
}

resource "aws_api_gateway_stage" "private_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.private_api.id
  stage_name    = "private"
  deployment_id = aws_api_gateway_deployment.private_api_deployment.id
  description   = "Private API Gateway Stage"
}

# ✅ API Gateway Resource Policy to Allow Anonymous Access
resource "aws_api_gateway_rest_api_policy" "private_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.private_api.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "execute-api:/*"
        Condition = {
          "StringNotEquals" : {
            "aws:sourceVpce" : "${aws_vpc_endpoint.apigw.id}"
          }
        }
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "execute-api:/*"
      }
    ]
  })
}

# API Gateway CloudWatch Role
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "api_gateway_cloudwatch" {
  name       = "api_gateway_cloudwatch_attachment"
  roles      = [aws_iam_role.api_gateway_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}
