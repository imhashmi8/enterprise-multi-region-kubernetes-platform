output "state_bucket_name" {
  description = "S3 bucket name to use in backend.tfvars for all other stacks."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name to use in backend.tfvars for all other stacks."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB lock table."
  value       = aws_dynamodb_table.terraform_locks.arn
}
