# Create an S3 bucket
resource "aws_s3_bucket" "top_secret_data" {
  bucket = "top-secret-data"
  acl    = "private"

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
}

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
resource "aws_iam_policy" "lambda" {
  name = "lambda_policy"
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
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = "lambda:InvokeFunction",
        Resource  = aws_lambda_function.process_order_function.arn,
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${aws_s3_bucket.top_secret_data.arn}"
          }
        }
      }
    ]
  })
}

# Attach IAM policy to Lambda execution role
resource "aws_iam_policy_attachment" "lambda" {
  name       = "lambda_attachment"
  roles      = [aws_iam_role.lambda_execution.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "process_order_function" {
  function_name    = "process-order-function"
  handler          = "lambda_function.lambda_handler"  
  runtime          = "python3.8"  
  memory_size      = 128
  timeout          = 10
  role             = aws_iam_role.lambda_execution.arn
  source_code_hash = filebase64sha256("lambda/lambda_function.zip")  
  filename         = "lambda/lambda_function.zip"  

  # Define environment variables if needed
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
  name           = "my-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Environment = "Production"
  }
}


