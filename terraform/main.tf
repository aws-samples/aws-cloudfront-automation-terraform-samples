data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "../src/lambda-cloudfront.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/cloudfront.zip"
}

resource "aws_iam_role" "cloudfront-role" {
  name = "cloudfront-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "S3Accesshelper" {
  name   = "cloudfront-accesspolicy"
  role   = aws_iam_role.cloudfront-role.id
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudfront:List*",
                "cloudfront:Get*",
                "cloudfront:UpdateDistribution",
                "cloudfront:UpdateCloudFrontOriginAccessIdentity"
            ],
            "Resource": "*"
        }
    ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.cloudfront-role.name
  count      = length(var.iam_policy_arn)
  policy_arn = var.iam_policy_arn[count.index]
}


resource "aws_lambda_function" "cloudfrontfunction" {
  function_name = "cloudfront-update-function"
  description = "This lambda function verifies the main project's dependencies, requirements and implement auxiliary functions"
  role        = aws_iam_role.cloudfront-role.arn
  handler     = "lambda-cloudfront.lambda_handler"
  filename    = data.archive_file.lambda_my_function.output_path
  runtime     = "python3.9"
  timeout     = 300
  memory_size = 128
  reserved_concurrent_executions = 1
  environment {
    variables = {
      cloudfront_distribution_id = var.cloudfront_distribution_id
    }
  }

}

resource "aws_cloudwatch_event_rule" "create_loadbalancer_event" {
  name        = "create_loadbalancer_event"
  description = "loadbalancer events"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.elasticloadbalancing"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "elasticloadbalancing.amazonaws.com"
    ],
    "eventName": [
      "CreateLoadBalancer"
    ]
  }
}
PATTERN
}


resource "aws_cloudwatch_event_target" "create_loadbalancer_event_target" {
  rule      = aws_cloudwatch_event_rule.create_loadbalancer_event.name
  target_id = "cloudfront-update"
  arn       = aws_lambda_function.cloudfrontfunction.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.cloudfrontfunction.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.create_loadbalancer_event.arn
}