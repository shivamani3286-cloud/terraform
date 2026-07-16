resource "aws_iam_role" "terraform_iam_role" {
    name = "terraform-iam-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = ["sts:AssumeRole"]
                Principal = {
                    Service = ["lambda.amazonaws.com"]
                }
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.terraform_iam_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "shiva" {
    function_name    = "terraform-lam"
    runtime          = "python3.11"
    handler          = "lambda_function.lambda_handler"
    role             = aws_iam_role.terraform_iam_role.arn
    filename         = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256

    depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}
