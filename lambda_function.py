import json
import boto3
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3', endpoint_url='http://localstack:4566', region_name='us-east-1')
    bucket = os.environ['BUCKET_NAME']
    
    s3.put_object(Bucket=bucket, Key='success_log.txt', Body=b'Lambda was triggered successfully!')
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'message': 'GET request successful. File created in S3!'})
    }