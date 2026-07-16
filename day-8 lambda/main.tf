resource "aws_iam_role" "terraform_lam_role" {
    name = "terraform-lam-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = ["sts:AssumeRole"]
                Principal = { Service = ["lambda.amazonaws.com"] }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.terraform_lam_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "terraform_lam" {
    function_name    = "terraform_lam"
    runtime          = "python3.11"
    handler          = "lambda_function.lambda_handler"
    role             = aws_iam_role.terraform_lam_role.arn
    filename         = "lambda_function_payload.zip"
    source_code_hash = filebase64sha256("lambda_function_payload.zip")
    timeout          = 900
    memory_size      = 128
}