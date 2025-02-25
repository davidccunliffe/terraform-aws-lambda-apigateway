# Output API Gateway ARN
output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.private_api.execution_arn
}

# Output API Gateway Invoke URL
output "api_gateway_invoke_url" {
  value = "curl -X GET ${aws_api_gateway_deployment.private_api_deployment.invoke_url}${aws_api_gateway_stage.private_api_stage.stage_name}/root"
}

# Output Lambda ARN
output "lambda_arn" {
  value = aws_lambda_function.hello_lambda.arn
}
