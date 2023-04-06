import boto3
import logging
import subprocess
from botocore.exceptions import ClientError

AWS_REGION = 'us-east-1'
boto3.session.Session(aws_access_key_id='test', aws_secret_access_key='test', region_name='us-east-1')
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
s3 = boto3.resource("s3", region_name=AWS_REGION, endpoint_url='http://localhost:4566')
BUCKET_NAME = 'test-cloud-hackathon-src-bucket'
KEY = 'Main.jar'
local_file = '/tmp' + KEY
s3.Bucket(BUCKET_NAME).download_file(KEY, local_file)
def handler(event,context):
    subprocess.call(['java', '-jar', local_file])
