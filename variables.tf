variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "schedule_expression" {
  description = "The schedule expression for triggering the Lambda function (e.g., cron or rate expression)"
  default     = "rate(1 day)"
}
variable "create_roles" {
  description = "Whether to create IAM roles"
  default     = false
}
variable "github_oauth_token" {
  description = "GitHub OAuth token for accessing the repository"
  type        = string
}


