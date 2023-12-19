import boto3
import json

def lambda_handler(event, context):
    
    api_gateway_name = event['detail']['requestParameters']['name'

    
    lambda_client = boto3.client('lambda')

    
    lambda_function_name = 'your-lambda-function-name'  # Replace with the name of your existing Lambda function
    lambda_function_arn = f'arn:aws:lambda:{context.invoked_function_arn.split(":")[3]}:{context.invoked_function_arn.split(":")[4]}:function:{lambda_function_name}'

    
    log_group_name = f'/aws/api-gateway/{api_gateway_name}'
    permission_statement_id = f'event-{api_gateway_name}'

    
    try:
        lambda_client.remove_permission(
            FunctionName=lambda_function_name,
            StatementId=permission_statement_id
        )
        print(f"Successfully removed CloudWatch Logs trigger for {api_gateway_name}")
    except lambda_client.exceptions.ResourceNotFoundException:
        print(f"CloudWatch Logs trigger not found for {api_gateway_name}. No action taken.")
    except Exception as e:
        print(f"An error occurred: {e}")
