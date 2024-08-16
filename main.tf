provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "ec2tarea_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "ec2_automation" {
  filename         = "lambda_function_payload.zip"
  function_name    = "ec2_automation"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "python3.9"
}

resource "aws_cloudwatch_event_rule" "ec2_automation_rule" {
  name                = "ec2_automation_rule"
  description         = "Triggers the Lambda function to automate EC2 tasks"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "ec2_automation_target" {
  rule      = aws_cloudwatch_event_rule.ec2_automation_rule.name
  target_id = "ec2_automation_lambda"
  arn       = aws_lambda_function.ec2_automation.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_automation_rule.arn
}

resource "aws_iam_role" "codebuild_role" {
  name = "pipeline-ec2-tarea"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_administrator_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
