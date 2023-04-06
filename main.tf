provider "aws" {
    access_key = "test"
    secret_key = "test"
    region = var.aws_region
    endpoints {
      apigateway     = "http://localhost:4566"
      apigatewayv2   = "http://localhost:4566"
      cloudformation = "http://localhost:4566"
      cloudwatch     = "http://localhost:4566"
      dynamodb       = "http://localhost:4566"
      ec2            = "http://localhost:4566"
      es             = "http://localhost:4566"
      elasticache    = "http://localhost:4566"
      firehose       = "http://localhost:4566"
      iam            = "http://localhost:4566"
      kinesis        = "http://localhost:4566"
      lambda         = "http://localhost:4566"
      rds            = "http://localhost:4566"
      redshift       = "http://localhost:4566"
      route53        = "http://localhost:4566"
      s3             = "http://s3.localhost.localstack.cloud:4566"
      secretsmanager = "http://localhost:4566"
      ses            = "http://localhost:4566"
      sns            = "http://localhost:4566"
      sqs            = "http://localhost:4566"
      ssm            = "http://localhost:4566"
      stepfunctions  = "http://localhost:4566"
      sts            = "http://localhost:4566"
    }
}

data "archive_file" "zip_lambda" {
    source_dir = "${path.module}/lambda"
    output_path = "${path.module}/lambda.zip"
    type = "zip"
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.env_name}_lambda_policy"
  description = "${var.env_name}_lambda_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:CopyObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.env_name}-src-bucket",
        "arn:aws:s3:::${var.env_name}-src-bucket/*"
      ]
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_copy_function" {
  name = "app_${var.env_name}_lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = "${aws_iam_role.s3_copy_function.id}"
  policy_arn = "${aws_iam_policy.lambda_policy.arn}"
}

resource "aws_lambda_permission" "allow_terraform_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_copy_function.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.source_bucket.arn}"
}

resource "aws_lambda_function" "s3_copy_function" {
  filename      = "lambda.zip"
  source_code_hash = data.archive_file.zip_lambda.output_base64sha256
  function_name = "${var.env_name}_s3_copy_lambda"
  role          = "${aws_iam_role.s3_copy_function.arn}"
  handler       = "hello.handler"
  runtime       = "python3.6"
}

resource "aws_s3_bucket" "source_bucket" {
    bucket = "${var.env_name}-src-bucket"
    force_destroy = true 
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${aws_s3_bucket.source_bucket.id}"
  lambda_function {
        lambda_function_arn = "${aws_lambda_function.s3_copy_function.arn}"
        events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_terraform_bucket]

}

output "source-s3-bucket" {
    value = "${aws_s3_bucket.source_bucket.id}"
}