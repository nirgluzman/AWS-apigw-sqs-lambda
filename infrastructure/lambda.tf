resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  # policy associated with a role that controls which principals (users, other roles, AWS services, etc.) can "assume" the role.
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# IAM policy to enable lambda to send logs to CloudWatch
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"  # Path in which to create the policy
  description  = "AWS IAM Policy for managing AWS lambda role"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  })
}

# Policy Attachment to attach the IAM policy to the IAM role.
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# CloudWatch Log Group resource -> when Terraform manages the log group, it is destroyed with 'terraform destroy'.
# https://advancedweb.hu/how-to-manage-lambda-log-groups-with-terraform/
resource "aws_cloudwatch_log_group" "lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.terraform_lambda_func.function_name}"
  retention_in_days = 14 # expiration to the log messages.
}

# Create a lambda function
resource "aws_lambda_function" "terraform_lambda_func" {
  function_name  = "Terraform-Lambda-Function"
  handler        = "hello.handler" # function entrypoint
  runtime        = "nodejs20.x"
  role           = aws_iam_role.lambda_role.arn
  filename       = "${path.module}/dummy.zip" # point to the temporary placeholder file

  # environment {   # Environment variables
  #   variables = {
  #   }
  # }
}
