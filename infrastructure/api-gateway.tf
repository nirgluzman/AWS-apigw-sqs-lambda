# API Gateway REST API
resource "aws_api_gateway_rest_api" "apigw" {
  description = "API Gateway as the secured entry point for SQS queue"
  name        = "ApiGwSqs"

  endpoint_configuration {
    types = ["REGIONAL"] # API endpoint resides in a specific AWS region.
  }
}

# Validation template to validate the POST request body.
resource "aws_api_gateway_request_validator" "apigw" {
  name                        = "payload-validator"
  rest_api_id                 = aws_api_gateway_rest_api.apigw.id
  validate_request_body       = true
  validate_request_parameters = false # path parameters, query string parameters, headers
}

resource "aws_api_gateway_model" "apigw" {
  name             = "payloadModel"
  description      = "validate the json body content conforms to spec"
  rest_api_id      = aws_api_gateway_rest_api.apigw.id
  content_type     = "application/json"
  schema           = <<EOF
    {
      "type" : "object",
      "required": [ "message"],
      "properties" : {
        "message": { "type": "string" }
      }
    }
    EOF
}

# define POST method at the root / of the API.
resource "aws_api_gateway_method" "post" {
  rest_api_id           = aws_api_gateway_rest_api.apigw.id
  resource_id           = aws_api_gateway_rest_api.apigw.root_resource_id
  http_method           = "POST"
  authorization         = "NONE"
  api_key_required      = false # specify if the method requires an API key

  request_validator_id  = aws_api_gateway_request_validator.apigw.id

  # Map of the API models used for the request's content type.
  request_models        = {
    "application/json" = aws_api_gateway_model.apigw.name
  }
}

# Integrate API Gateway with SQS Queue - forward records into the SQS queue.
resource "aws_api_gateway_integration" "sqs" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_rest_api.apigw.root_resource_id
  http_method = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS" # AWS services
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.queue.name}"

  # method request of an unmapped content type will be rejected with an HTTP 415 Unsupported Media Type response.
  passthrough_behavior    = "NEVER"

  # Authentication mechanism used when API Gateway integrates with AWS backend services.
  credentials             = aws_iam_role.apigw.arn

  # Map of request query string parameters and headers that should be passed to the backend responder.
  # This configuration ensures that the request sent to the integration always includes a "Content-Type" header set to "application/x-www-form-urlencoded".
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  # Map of the integration's request templates.
  # This configuration defines a template that transforms the request body into a specific format only when the request content type is "application/json".
  # The transformation essentially prepends "Action=SendMessage&MessageBody= to the original request body content.
  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

# Provide an HTTP Method Integration Response for an API Gateway Resource.
# Define a basic 200 handler for successful requests with a custom response message.
resource "aws_api_gateway_integration_response" "sqs_integration_response" {
  rest_api_id         = aws_api_gateway_rest_api.apigw.id
  resource_id         = aws_api_gateway_rest_api.apigw.root_resource_id
  http_method         = aws_api_gateway_method.post.http_method
  status_code         = aws_api_gateway_method_response.response_200.status_code
  selection_pattern   = "^2[0-9][0-9]" # regex pattern to match any 2XX status codes that come back from SQS

  response_templates  = {
    "application/json" = "{\"message\": \"message sent!\"}"
  }

  depends_on = [aws_api_gateway_integration.sqs]
}

# Provide an HTTP Method Response for an API Gateway Resource.
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_rest_api.apigw.root_resource_id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  # Instructs the API Gateway to not apply any model transformation to the response body for requests that return JSON data (application/json).
  response_models = {
    "application/json" = "Empty"
  }
}

# Deployment of API Gateway = snapshot of the REST API configuration.
# The deployment resource is where you specify the details of the API deployment, such as the stage name.
# Every time the API Gateway configuration changes, we have to explicitly deploy the same on a stage of our choice.
resource "aws_api_gateway_deployment" "apigw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = "dev" # API is accessible through the “dev” stage
  depends_on  = [aws_api_gateway_integration.sqs]
}

# Role for API Gateway with the necessary permissions to SendMessage to SQS queue.
resource "aws_iam_role" "apigw" {
  name = "apigw-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Sid": ""
    }
  ]
}
EOF
}

# Policy for access the SQS queue and read & write logs to CloudWatch.
resource "aws_iam_role_policy" "api_gw_policy" {
  name = "apigw-policy"
  role = aws_iam_role.apigw.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": ["sqs:SendMessage"],
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.queue.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}
