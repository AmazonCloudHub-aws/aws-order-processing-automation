# Output bucket name and Lambda function ARN
output "bucket_name" {
  value = aws_s3_bucket.top_secret_data.bucket
}

output "lambda_arn" {
  value = aws_lambda_function.process_order_function.arn
}