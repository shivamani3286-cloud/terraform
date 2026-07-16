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

resource "aws_s3_bucket" "my_bucket" {
    bucket = "ghehjfhjfbhdf"
}

resource "aws_lambda_function" "terraform_lam" {
    function_name = "terraform_lam"
    runtime        = "python3.11"
    handler        = "lambda_function.lambda_handler"
    role           = aws_iam_role.terraform_lam_role.arn
    s3_bucket      = aws_s3_bucket.my_bucket.id
    s3_key         = "lambda_function (1).zip"
    timeout        = 900
    memory_size    = 128

    depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}

resource "aws_cloudwatch_event_rule" "terraform-lam-rule" {
    name                = "bhdfbhddfhj"
    schedule_expression = "cron(0/5 * * * ? *)"
    description         = "lam-terra-event"
}

resource "aws_cloudwatch_event_target" "lam-tag" {
    rule      = aws_cloudwatch_event_rule.terraform-lam-rule.name
    target_id = "lambda-schedule-target"
    arn       = aws_lambda_function.terraform_lam.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.terraform_lam.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.terraform-lam-rule.arn
}