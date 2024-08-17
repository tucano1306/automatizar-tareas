variable "aws_region" {
  description = "The AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "schedule_expression" {
  description = "The schedule expression for the EventBridge rule"
  default     = "rate(5 minutes)"
}

variable "create_roles" {
  description = "Whether to create IAM roles"
  default     = false
}

variable "github_oauth_token" {
  description = "GitHub OAuth token for accessing the repository"
  type        = string
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "tareas_ec2_rol" {
  count = var.create_roles ? 1 : 0
  name  = "tareas_ec2_rol"

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
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  count      = var.create_roles ? 1 : 0
  role       = aws_iam_role.tareas_ec2_rol[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  count = var.create_roles ? 1 : 0
  name  = "lambda_ec2_policy"
  role  = aws_iam_role.tareas_ec2_rol[count.index].id

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
  function_name    = "funcion_ec2_tarea"
  role             = aws_iam_role.tareas_ec2_rol[0].arn
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
  name = "pipeline_ec2_tarea"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_administrator_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codepipeline" "example_pipeline" {
  name     = "example-pipeline"
  role_arn = aws_iam_role.codebuild_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "tucano1306"
        Repo       = "automatizar-tareas"
        Branch     = "main"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy_Terraform"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.terraform_project.name
      }
    }
  }
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = "codepipeline-artifact-store-example"
}

resource "aws_codebuild_project" "terraform_project" {
  name          = "TerraformProject"
  build_timeout = 5

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_VAR_example"
      value = "example_value"
    }
  }

  service_role = aws_iam_role.codebuild_role.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

        




