terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"

    }
  }
}

# Configuring the AWS Provider
provider "aws" {
  region = "eu-west-1"
  access_key = "access"
  secret_key = "secret"
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name        = "Baha_Kinesis_Babbel_Stream"
  shard_count = 1
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "./Bubble_Transformer_Function.zip"
  function_name = "Bubble_Transformer_Function"
  role          = aws_iam_role.Baha_Lambda_Babbel_Role.arn
  handler       = "Bubble_Transformer_Function.lambda_handler"

  source_code_hash = filebase64sha256("./Bubble_Transformer_Function.zip")

  runtime = "python3.8"
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn  = aws_kinesis_stream.kinesis_stream.arn
  function_name     = aws_lambda_function.lambda_function.arn
  starting_position = "TRIM_HORIZON"
  batch_size        = 278

  lifecycle {
    ignore_changes = [
      event_source_arn, 
    ]
  }
}
resource "aws_dynamodb_table" "ProcessedEvents" {
  name           = "ProcessedEvents"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_uuid"
 

  attribute {
    name = "event_uuid"
    type = "S"
  }

  tags = {
    Name = "ProcessedEvents"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "baha-s3-babbel-bucket"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "Baha_Lambda_Babbel_Role" {
  name = "Baha_Lambda_Babbel_Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_policy" "dynamodb_access" {
  name        = "DynamoDBAccessPolicy"
  description = "Customized Policy to allow Lambda function to use DynamoDB like a cache"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBTableAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:eu-west-1:420106492114:table/ProcessedEvents"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = "Baha_Lambda_Babbel_Role"
  policy_arn = aws_iam_policy.dynamodb_access.arn
}


resource "aws_iam_policy" "s3_access" {
  name        = "S3AccessPolicy"
  description = "Customized Policy for s3 interactions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::baha-s3-babbel-bucket",
        "arn:aws:s3:::baha-s3-babbel-bucket/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = "Baha_Lambda_Babbel_Role"
  policy_arn = aws_iam_policy.s3_access.arn
}


resource "aws_iam_role_policy_attachment" "kinesis_read_only_access" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}


resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_kinesis_execution_role" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

