import boto3
import json

def lambda_handler(event, context):
    
    api_gateway_name = event['detail']['requestParameters']['name'

    
    lambda_client = boto3.client('lambda')

    # Create a new CloudWatch Logs trigger for the Lambda function
    lambda_function_name = 'your-lambda-function-name'  # Replace with the name of your existing Lambda function
    log_group_name = f'/aws/api-gateway/{api_gateway_name}'
    lambda_function_arn = f'arn:aws:lambda:{context.invoked_function_arn.split(":")[3]}:{context.invoked_function_arn.split(":")[4]}:function:{lambda_function_name}'

    response = lambda_client.add_permission(
        FunctionName=lambda_function_name,
        StatementId=f'event-{api_gateway_name}',
        Action='lambda:InvokeFunction',
        Principal='logs.amazonaws.com',
        SourceArn=f'arn:aws:logs:{context.invoked_function_arn.split(":")[3]}:{context.invoked_function_arn.split(":")[4]}:log-group:{log_group_name}:*'
    )

    print(response)
