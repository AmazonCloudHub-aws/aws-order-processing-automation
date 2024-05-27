# Create an S3 bucket
resource "aws_s3_bucket" "top_secret_data" {
  bucket = "top-secret-data"
  acl    = "private"

  provisioner "local-exec" {
    command = "bash ${path.module}/check_bucket.sh ${aws_s3_bucket.top_secret_data.id}"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "log-expiration"
    enabled = true

    expiration {
      days = 90
    }
  }

  tags = {
    Name        = "top-secret-data"
    Environment = "Production"
  }
}

# Setup S3 bucket notification to trigger a Lambda function
resource "aws_s3_bucket_notification" "top_secret_notification" {
  bucket = aws_s3_bucket.top_secret_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_order_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }
}

# Create a Lambda function IAM role
resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Define IAM policy for Lambda execution role
resource "aws_iam_policy" "lambda_logs_policy" {
  name = "lambda_logs_policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource  = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_dynamodb_policy" {
  name = "lambda_s3_dynamodb_policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "s3:GetObject",
          "s3:PutObject",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "lambda:InvokeFunction"  # Ensure the Lambda function can invoke other Lambda functions if needed
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.top_secret_data.bucket}/*",
          aws_dynamodb_table.table.arn,
          aws_lambda_function.process_order_function.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_s3_dynamodb_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_s3_dynamodb_policy.arn
}

# Attach AWSLambdaBasicExecutionRole managed policy for basic Lambda execution permissions
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function
resource "aws_lambda_function" "process_order_function" {
  function_name    = "process-order-function"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  memory_size      = 256
  timeout          = 15
  role             = aws_iam_role.lambda_execution.arn
  source_code_hash = filebase64sha256("lambda/lambda_function.zip")
  filename         = "lambda/lambda_function.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.table.name
    }
  }

  tags = {
    Environment = "Production"
  }
}

# Create a DynamoDB table
resource "aws_dynamodb_table" "table" {
  name         = "my-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = "Production"
  }
}

# Create CloudWatch log group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/process-order-function"
  retention_in_days = 14

  tags = {
    Environment = "Production"
  }
}

# CloudWatch Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "LambdaErrorAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.lambda_notifications.arn]
  dimensions = {
    FunctionName = aws_lambda_function.process_order_function.function_name
  }

  tags = {
    Environment = "Production"
  }
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "lambda_notifications" {
  name = "lambda-notifications"

  tags = {
    Environment = "Production"
  }
}

# Create an SNS topic subscription
resource "aws_sns_topic_subscription" "lambda_notifications_email" {
  topic_arn = aws_sns_topic.lambda_notifications.arn
  protocol  = "email"
  endpoint  = "dhamseygithub@gmail.com"  
}
