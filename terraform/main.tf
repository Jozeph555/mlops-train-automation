provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_iam_role" "lambda_exec" {
 name = "lambda_exec_role"
 assume_role_policy = jsonencode({
  Version = "2012-10-17",
  Statement = [{
   Action = "sts:AssumeRole",
   Effect = "Allow",
   Principal = { Service = "lambda.amazonaws.com" }
  }]
 })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
 role    = aws_iam_role.lambda_exec.name
 policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "validate" {
 filename     = "${path.module}/lambda/validate.zip"
 function_name  = "validateData"
 role       = aws_iam_role.lambda_exec.arn
 handler     = "validate.handler"
 runtime     = "python3.10"
 source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")
}

resource "aws_lambda_function" "log_metrics" {
 filename     = "${path.module}/lambda/log_metrics.zip"
 function_name  = "logMetrics"
 role       = aws_iam_role.lambda_exec.arn
 handler     = "log_metrics.handler"
 runtime     = "python3.10"
 source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")
}

data "aws_iam_policy_document" "stepfunction_trust" {
 statement {
  actions = ["sts:AssumeRole"]
  principals {
   type    = "Service"
   identifiers = ["states.amazonaws.com"]
  }
 }
}

resource "aws_iam_role" "stepfunction_exec" {
 name        = "stepfunction_exec_role"
 assume_role_policy = data.aws_iam_policy_document.stepfunction_trust.json
}

resource "aws_iam_role_policy_attachment" "stepfunction_policy" {
 role    = aws_iam_role.stepfunction_exec.name
 policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_sfn_state_machine" "mlops_pipeline" {
 name   = "MLOpsPipeline"
 role_arn = aws_iam_role.stepfunction_exec.arn
 definition = jsonencode({
  StartAt = "ValidateData",
  States = {
   ValidateData = {
    Type   = "Task",
    Resource = aws_lambda_function.validate.arn,
    Next   = "LogMetrics"
   },
   LogMetrics = {
    Type   = "Task",
    Resource = aws_lambda_function.log_metrics.arn,
    End   = true
   }
  }
 })
}