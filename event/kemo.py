import boto3
import os

firehose_stream_name = os.environ['FIREHOSE_STREAM_NAME']
log_group_name = os.environ['LOG_GROUP_NAME']

def lambda_handler(event, context):
    logs = []
  
    if event['logGroupName'] == log_group_name:
        logs.append({
            'Data': json.dumps(event)
        })

    if logs:
        firehose = boto3.client('firehose'

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
