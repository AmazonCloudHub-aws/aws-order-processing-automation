import json
import boto3

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('your_dynamodb_table_name')


def lambda_handler(event, context):
    try:
        # Extract necessary information from the S3 event
        s3_bucket = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']

        # Assuming data extraction and formatting here
        data_to_store = {
            's3_bucket': s3_bucket,
            's3_key': s3_key,
            # Add other attributes as needed
        }

        # Write data to DynamoDB
        table.put_item(Item=data_to_store)

        return {
            'statusCode': 200,
            'body': json.dumps('Data written to DynamoDB successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(str(e))
        }
