variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-west-2"
}

variable "schedule_expression" {
  description = "The schedule expression for triggering the Lambda function (e.g., cron or rate expression)"
  default     = "rate(1 day)"
}
variable "create_roles" {
  description = "Whether to create IAM roles"
  default     = false
}


