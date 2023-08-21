provider "aws" {
  region  = "us-east-1"
  profile = "jenny"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = "MyTestLambda"
  filename      = "lambda_function_payload.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_full_access_ecs_dynamodb" {
  name        = "LambdaFullAccessECSDynamoDB"
  description = "Full permissions for ECS and DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ecs:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_ecs_dynamodb_attachment" {
  policy_arn = aws_iam_policy.lambda_full_access_ecs_dynamodb.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}
