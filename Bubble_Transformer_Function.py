import boto3
import json
import base64
from datetime import datetime
import logging
# line to see whether the zip step is working as it should be (attempt3)
# Initializing logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ProcessedEvents')

S3_BUCKET_NAME = 'baha-s3-babbel-bucket'
S3_KEY_PREFIX = 'babbelevents/'

def lambda_handler(event, context):
    try:
        for record in event['Records']:
            # Decoding the data from base64 encoding
            payload_bytes = base64.b64decode(record['kinesis']['data'])
            payload = json.loads(payload_bytes)

            # Checking if event has been processed before
            event_uuid = payload['event_uuid']
            response = table.get_item(Key={'event_uuid': event_uuid})
            if 'Item' in response:
                logger.info(f'Event {event_uuid} has already been processed, skipping.')
                continue

            # Extracting fields from the payload
            created_at_seconds = round(payload['created_at'] / 1000)
            created_datetime_iso = datetime.utcfromtimestamp(created_at_seconds).isoformat()
            L = payload['event_name'].split(':')
            event_type = L[0]
            event_subtype = L[1] if len(L) > 1 else 'n.a'

            # Adding additional fields to the payload
            payload['created_datetime'] = created_datetime_iso
            payload['event_type'] = event_type
            payload['event_subtype'] = event_subtype

            # Converting payload to JSON string
            modified_payload = json.dumps(payload)

            # Constructig S3 key with meaningful format
            s3_timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')
            s3_key = f'{S3_KEY_PREFIX}{event_type}/{s3_timestamp}_{payload["event_uuid"]}.json'

            # Uploading modified payload to S3
            s3.put_object(
                Bucket=S3_BUCKET_NAME,
                Key=s3_key,
                Body=modified_payload
            )

            # Adding event to DynamoDB
            table.put_item(Item={'event_uuid': event_uuid})

        logger.info('Events processed and saved to S3 successfully!')
        return {
            'statusCode': 200,
            'body': json.dumps('Events processed and saved to S3 successfully!')
        }
    except Exception as e:
        logger.error(f'Error processing event: {e}')
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing event: {e}')
        }
