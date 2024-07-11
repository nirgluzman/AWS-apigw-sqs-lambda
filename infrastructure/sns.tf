# Simple Notification Service (SNS)

# Create an SNS topic
resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
}

# Create an SNS topic subscription
resource "aws_sns_topic_subscription" "notification_subscription" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol = "email"
  endpoint = "test@test.com"
}
