 provider "aws" {
  region = var.aws_region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_iam_role" "tareas_ec2_rol" {
  name = "tareas_ec2_rol_${random_string.suffix.result}"

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.tareas_ec2_rol.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_policy_${random_string.suffix.result}"
  role = aws_iam_role.tareas_ec2_rol.id

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

resource "aws_lambda_function" "funcion_ec2_tarea" {
  filename         = "lambda_function_payload.zip"
  function_name    = "funcion_ec2_tarea_${random_string.suffix.result}"
  role             = aws_iam_role.tareas_ec2_rol.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "python3.9"
}

resource "aws_cloudwatch_event_rule" "ec2_automation_rule" {
  name                = "ec2_automation_rule_${random_string.suffix.result}"
  description         = "Triggers the Lambda function to automate EC2 tasks"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "ec2_automation_target" {
  rule      = aws_cloudwatch_event_rule.ec2_automation_rule.name
  target_id = "ec2_automation_lambda"
  arn       = aws_lambda_function.funcion_ec2_tarea.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.funcion_ec2_tarea.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_automation_rule.arn
}

resource "aws_iam_role" "codebuild_role" {
  name = "pipeline_ec2_tarea_${random_string.suffix.result}"

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_administrator_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

        




