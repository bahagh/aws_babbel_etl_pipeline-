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
  access_key = "AKIAWDUCMLDJF3ZF7BEK"
  secret_key = "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"
}



#terraform resource for my kinesis data stream
resource "aws_kinesis_stream" "kinesis_stream" {
  name        = "Baha_Kinesis_Babbel_Stream"
  shard_count = 1
}




#terraform resource for my lambda fuction 
resource "aws_lambda_function" "lambda_function" {
  filename      = "./lambda/Bubble_Transformer_Function.zip"
  function_name = "Bubble_Transformer_Function"
  role          = aws_iam_role.Baha_Lambda_Babbel_Role.arn
  handler       = "Bubble_Transformer_Function.lambda_handler"

  source_code_hash = filebase64sha256("./lambda/Bubble_Transformer_Function.zip")

  runtime = "python3.8"
}



# terraform resource for the kinesis and lambda function event mapping (i needed to check whether the event mapping is already existing or not because for some reason not as terraform should it would always try to create it even thought it was just created in the last terraform apply)
# made the batch size to 278/second so it can process around 1000000/hour 
variable "create_lambda_mapping" {
  default = false
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  count             = var.create_lambda_mapping ? 1 : 0
  event_source_arn  = aws_kinesis_stream.kinesis_stream.arn
  function_name     = aws_lambda_function.lambda_function.arn
  starting_position = "TRIM_HORIZON"
  batch_size        = 278

  lifecycle {
    create_before_destroy = true
  }
}


# terraform resource for my dynamodb (i'm using a dynamodb table as a way to handle duplicate events like a cache in such way each uuid passed by the lambda function will be stored in the dynamodb table and as long as the uuid of the event is not existing in the dynamodb it will be processed other wise if it does exist the event wont be tranformed and it will be skipped to save compute time and store and to keep the data in s3 relevant and organized )
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




# terraform resource for my s3 bucket 
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "baha-s3-babbel-bucket"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}




# terraform resource to bock public access for my s3 bucket
resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}



# terraform resource to create the iam role i'll be using to make the connections i need between the different services possible
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





# Customized policy containing the right i need from the dynamo table (its possible just use the predefined full access to dynamodb policy but it"s better to follow the principle of the least number of privilege and to use the specific requirements i'd need)
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



# granting the dynamodb policy to the iam role i created earlier 
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = "Baha_Lambda_Babbel_Role"
  policy_arn = aws_iam_policy.dynamodb_access.arn
}



# customized access policy for s3
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




#granting the customized policy i created for interacting with s3 to my iam role i created earlier
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = "Baha_Lambda_Babbel_Role"
  policy_arn = aws_iam_policy.s3_access.arn
}





# attaching policy to read data from kinesis 
resource "aws_iam_role_policy_attachment" "kinesis_read_only_access" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}




# granting lambda basic execution role to my iam role i created before 
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



# granting kinesis execution role to my iam role i created before 
resource "aws_iam_role_policy_attachment" "lambda_kinesis_execution_role" {
  role       = aws_iam_role.Baha_Lambda_Babbel_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

