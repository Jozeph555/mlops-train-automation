output "state_machine_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.mlops_pipeline.arn
}

output "validate_lambda_arn" {
  description = "ARN of the validate Lambda function"
  value       = aws_lambda_function.validate.arn
}

output "log_metrics_lambda_arn" {
  description = "ARN of the log_metrics Lambda function"
  value       = aws_lambda_function.log_metrics.arn
}