import boto3
import re

def lambda_handler(event, context): 
    # Initialize the CloudWatch Logs client
    logs_client = boto3.client('logs')

    # Extract restApiId and stageName from CloudTrail event
    request_params = event.get('detail', {}).get('requestParameters', {})
    rest_api_id = request_params.get('restApiId')
    stage_name = request_params.get('stageName')

    # Form the log group prefix pattern based on extracted values
    log_group_prefix = f'API-Gateway-Execution-Logs_{rest_api_id}/{stage_name}'

    # Get a list of all log groups
    log_groups = logs_client.describe_log_groups()['logGroups']

    # Iterate through each log group and delete those that match the pattern
    for log_group in log_groups:
        log_group_name = log_group['logGroupName']
        if log_group_name.startswith(log_group_prefix):
            logs_client.delete_log_group(logGroupName=log_group_name)
            print(f"Deleted log group: {log_group_name}")

    return {
        'statusCode': 200,
        'body': 'Log groups deletion complete'
    }
