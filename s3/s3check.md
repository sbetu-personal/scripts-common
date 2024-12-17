import boto3

# Replace with your actual bucket name
BUCKET_NAME = "<your-bucket-name>"

s3_client = boto3.client('s3')

# List all objects in the bucket
response = s3_client.list_objects_v2(Bucket=BUCKET_NAME)
if 'Contents' not in response:
    print("No objects found in the bucket.")
    exit(0)

for obj in response['Contents']:
    key = obj['Key']
    # Get the object's metadata
    head_response = s3_client.head_object(Bucket=BUCKET_NAME, Key=key)
    encryption = head_response.get('ServerSideEncryption', 'None')
    
    if encryption == 'None':
        print(f"Unencrypted object: {key}")
    else:
        print(f"Encrypted object: {key} with SSE: {encryption}")