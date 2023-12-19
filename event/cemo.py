import boto3
import os

firehose_stream_name = os.environ['FIREHOSE_STREAM_NAME']
log_group_name = os.environ['LOG_GROUP_NAME'

def lambda_handler(event, context):
    logs = []
    
    
    logs_client = boto3.client('logs')

    # List all log streams
    log_streams = logs_client.describe_log_streams(
        logGroupName=log_group_name,
        orderBy='LastEventTime',
        descending=True
    )['logStreams']

    for log_stream in log_streams:
        
        log_events = logs_client.get_log_events(
            logGroupName=log_group_name,
            logStreamName=log_stream['logStreamName'],
            startFromHead=True
        )['events']

        for log_event in log_events:
            logs.append({
                'Data': log_event['message']
            })

    if logs:
        
        firehose = boto3.client('firehose')

        
        response = firehose.put_record_batch(
            DeliveryStreamName=firehose_stream_name,
            Records=logs
        )

        # Return a response
        return {
            'statusCode': 200,
            'body': 'Logs sent to Firehose successfully!'
        }
    else:
        return {
            'statusCode': 200,
            'body': 'No logs to send to Firehose.'
        }
