terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

    endpoints {
  s3         = "http://127.0.0.1:4566"
  lambda     = "http://127.0.0.1:4566"
  apigateway = "http://127.0.0.1:4566"
  # Видаліть або закоментуйте рядок iam
}
}

resource "aws_s3_bucket" "lab_bucket" {
  bucket = "floci-lab-bucket"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "api_lambda" {
  function_name    = "FlociApiLambda"
  role = "arn:aws:iam::000000000000:role/dummy-role"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lab_bucket.bucket
    }
  }
}

resource "aws_api_gateway_rest_api" "lab_api" {
  name = "Floci-Lab-API"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.lab_api.id
  parent_id   = aws_api_gateway_rest_api.lab_api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "api_get" {
  rest_api_id   = aws_api_gateway_rest_api.lab_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lab_api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.lab_api.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.lab_api.id}/dev/_user_request_/hello"
}