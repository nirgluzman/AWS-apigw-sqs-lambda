# API Gateway - SQS - Lambda - SNS Integration

## GitHub repo

- <https://github.com/nirgluzman/Terraform-ApiGW-SQS-Lambda.git>

## Resources

- <https://cdk.entest.io/arch/serverless-demo#api-gateway-sqs-lambad-integration>
- <https://youtu.be/2p_yKCQeXNw?si=13Qy1YHMZpRM7NyF>
- <https://medium.com/aws-lambda-serverless-developer-guide-with-hands/amazon-sns-developing-with-aws-sdk-to-interact-serverless-apis-930e98c3a29a>

## Architecture

- API Gateway - the secured entry point for SQS queue.
- SQS Queue - an event source for Lambda to buffer for high demand and timeouts.
- Lambda - publishes SNS message for notification.
- SNS

## Update the code of a Lambda function

```bash
aws lambda update-function-code \
    --function-name  process-queue-message \
    --zip-file fileb://index.zip \
    --region us-east-1
```

## Integrations for REST APIs in API Gateway

- <https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-integration-settings.html>

- `Integration request` involves: configuring how to pass client-submitted method requests to the
  backend; configuring how to transform the request data, if necessary, to the integration request
  data; and specifying which Lambda function to call, specifying which HTTP server to forward the
  incoming request to, or specifying the AWS service action to invoke.

- `Integration response` (applicable to non-proxy integrations only) involves: configuring how to
  pass the backend-returned result to a method response of a given status code, configuring how to
  transform specified integration response parameters to preconfigured method response parameters,
  and configuring how to map the integration response body to the method response body according to
  the specified body-mapping templates.

## API Gateway to SQS queue

- <https://gist.github.com/afloesch/dc7d8865eeb91100648330a46967be25>

- <https://spacelift.io/blog/terraform-api-gateway>
