# Create an SQS queue to serve as an event source for our Lambda function.
# Upon detecting a new message in the queue, SQS automatically triggers the Lambda function.
# https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html

# SQS queue as an event source for Lambda to buffer for high demand and timeouts.
resource "aws_sqs_queue" "queue" {
  name                      = "MessageQueue"
  message_retention_seconds = 86400  # 1 day in seconds
}

# Event source from SQS to Lambda - this allows Lambda functions to get events from SQS.
# This resource is used to configure a connection between an AWS Lambda function and an event source.
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn        = aws_sqs_queue.queue.arn
  function_name           = aws_lambda_function.sqs_processor.arn
  enabled                 = true  # Determines if the mapping will be enabled on creation (defualt = true).
  batch_size              = 1     # The largest number of records that Lambda will retrieve from your event source at the time of invocation.
  maximum_batching_window_in_seconds = 0 # The maximum amount of time to gather records before invoking the function.
  function_response_types = ["ReportBatchItemFailures"]
}

# By default, when a Lambda function is triggered by an SQS event and finishes processing the message, Lambda doesn't send any specific response back to the SQS queue. The message remains in the queue until its visibility timeout expires or it's explicitly deleted.
# function_response_types argument allows you to configure how Lambda should handle the SQS message after processing:
# ReportBatchItemFailures - This is the default option, it sends details of failed message(s) to Amazon SQS.
