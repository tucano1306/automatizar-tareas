variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "schedule_expression" {
  description = "The schedule expression for triggering the Lambda function (e.g., cron or rate expression)"
  default     = "rate(1 day)"
}
