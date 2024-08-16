output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.funcion_ec2_tarea.function_name
}

output "cloudwatch_event_rule_name" {
  description = "The name of the CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.ec2_automation_rule.name
}
