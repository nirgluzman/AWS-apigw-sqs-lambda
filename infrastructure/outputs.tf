# Outputs from the resources created by Terraform

output "apigw-url" {
  value = aws_api_gateway_deployment.apigw_deployment.invoke_url
}
