# Lambda Execution Policy
resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "LambdaExecutionPolicy_api"
  description = "Policy allowing Lambda execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:PutSubscriptionFilter"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-1:<AWS_ACC_NUM>:log-group:API-Gateway-Execution-Logs_*:*" #Update AWS Account Number
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "arn:aws:iam::<AWS_ACC_NUM>:role/firehose_subscription_role"  #Update AWS Account Numbe
      }
    ]
  })
}

# Lambda Logs Policy
resource "aws_iam_policy" "lambda_logs_policy" {
  name        = "LambdaLogsPolicy_api"
  description = "Policy for Lambda logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-1:<AWS_ACC_NUM>:*"   #Update AWS Account Numbe
      },
      {
        Action   = [
          "logs:CreateLogStream",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-1:<AWS_ACC_NUM>:log-group:/aws/lambda/<NAME OF YOUR LAMBDA>:*"    #Update AWS Account Numbe
      }
    ]
  })
}

# Lambda Logs Role
resource "aws_iam_role" "lambda_logs_role" {
  name = "LambdaLogsRole_api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach Lambda Execution Policy to Lambda Logs Role
resource "aws_iam_policy_attachment" "lambda_execution_attachment" {
  name       = "LambdaExecutionPolicyAttachment"
  roles      = [aws_iam_role.lambda_logs_role.name]
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

# Attach Lambda Logs Policy to Lambda Logs Role
resource "aws_iam_policy_attachment" "lambda_logs_attachment" {
  name       = "LambdaLogsPolicyAttachment"
  roles      = [aws_iam_role.lambda_logs_role.name]
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attach" {
  role       = aws_iam_role.lambda_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "LambdaExecutionRole_api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach Lambda Execution Policy to Lambda Execution Role
resource "aws_iam_policy_attachment" "lambda_execution_role_attachment" {
  name       = "LambdaExecutionPolicyAttachment_Api"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

############### End of IAM Permission #############

################# Lambda Function to Create subscription and events ###############

######### Create Lambda ##################
resource "aws_lambda_function" "subscription_lambda" {
  function_name = "exampleLambdaFunction"
  filename      = "./resources/deploy_logs.zip" # Create File name as deploy_logs
  handler       = "deploy_logs.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_logs_role.arn
  timeout       = 60  # Adjust timeout as needed
  
  environment {
    variables = {
      FIREHOSE_STREAM_NAME = "demo-one", #UPDATE #provide stream name
      FIREHOSE_ROLE_ARN    = aws_iam_role.firehose_subscription_role.arn
      # Add other environment variables as needed
    }
  }
}


########### Create Event Rule ##############

resource "aws_cloudwatch_event_rule" "logs_group_create_rule" {
  name        = "logs-groups-cloudtrail-rule"
  description = "EventBridge rule for CloudTrail"

  event_pattern = <<PATTERN
{
  "source": ["aws.logs"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["logs.amazonaws.com"],
    "eventName": ["CreateLogGroup"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "example_target" {
  rule      = aws_cloudwatch_event_rule.logs_group_create_rule.name
  arn       = aws_lambda_function.subscription_lambda.arn 
}

resource "aws_lambda_permission" "allow_eventbridge_add" {
  statement_id  = "AllowExecutionFromCloudWatchEvents_lgroups"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscription_lambda.function_name 
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.logs_group_create_rule.arn
}
######### End of Create subscription Lambda and event bridge #############


########### **** Second Lambda Function and Event for Delete Group **** ########

######### Create Lambda ##################
resource "aws_lambda_function" "loggroups_remove_lambda" {
  function_name = "Delete_Loggroups"
  filename      = "./resources/log_groups.zip" # Create File name as deploy_logs
  handler       = "log_groups.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_execution_delete_role.arn
  timeout       = 60  # Adjust timeout as needed
}


########### Create Event Rule for delete log groups ##############

resource "aws_cloudwatch_event_rule" "logs_group_delete_rule" {
  name        = "logs-groups-cloudtrail-rule-delete"
  description = "EventBridge rule for CloudTrail for delete"

  event_pattern = <<PATTERN
{
  "source": ["aws.apigateway"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["apigateway.amazonaws.com"],
    "eventName": ["DeleteStage"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "delete_group_target" {
  rule      = aws_cloudwatch_event_rule.logs_group_delete_rule.name
  arn       = aws_lambda_function.loggroups_remove_lambda.arn 
}

resource "aws_lambda_permission" "delete_eventbridge_add" {
  statement_id  = "AllowExecutionFromCloudWatchEvents_lgroups_delete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.loggroups_remove_lambda.function_name 
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.logs_group_delete_rule.arn
}
#################### END of Delete Log groups Lambda and it's events ##################

############ IAM Permission for Creating Logs Subscription ###########

resource "aws_iam_role" "firehose_subscription_role" {
  name = "firehose-subscription-role"
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "logs.amazonaws.com"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringLike": {
            "aws:SourceArn": "arn:aws:logs:us-east-1:<AWS_ACC_NUM>:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_subscription_policy" {
  name        = "firehose-subscription-policy"
  description = "Policy allowing PutRecord to Firehose"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
            "firehose:PutRecord",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:PutSubscriptionFilter",
            "kinesis:PutRecord"
        ]
        "Resource": "<PUT FIREHOSE STREAM NAME ARN>"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_attach" {
  role       = aws_iam_role.firehose_subscription_role.name
  policy_arn = aws_iam_policy.firehose_subscription_policy.arn
}

################ END of IAM Permission ##########

########### IAM Permission for Delete Log groups ########

resource "aws_iam_policy" "lambda_logs_delete_policy" {
  name        = "LambdaLogsPolicy"
  description = "Policy to describe and delete CloudWatch log groups"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:DescribeLogGroups",
          "logs:DeleteLogGroup"
        ],
        Resource = "*"  # You can specify specific log group ARNs if needed
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution_delete_role" {
  name = "LambdaExecutionRole_Delete_CW_logs"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "delete_logs_policy_attachment" {
  role       = aws_iam_role.lambda_execution_delete_role.name
  policy_arn = aws_iam_policy.lambda_logs_delete_policy.arn
}


resource "aws_iam_role_policy_attachment" "lambda_basic_execution_delete" {
  role       = aws_iam_role.lambda_execution_delete_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

############### End of IAM Permission ################
