Below is an updated Python script that outputs object keys and their encryption status in CSV format. This script uses Python’s built-in csv module for clean CSV output.

import boto3
import csv
import sys

# Replace with your actual bucket name
BUCKET_NAME = "<your-bucket-name>"

s3_client = boto3.client('s3')

response = s3_client.list_objects_v2(Bucket=BUCKET_NAME)
if 'Contents' not in response:
    print("No objects found in the bucket.")
    sys.exit(0)

# Open a CSV writer that outputs to stdout.
# If you prefer a file, replace sys.stdout with open('output.csv', 'w', newline='', encoding='utf-8')
writer = csv.writer(sys.stdout)
# Write the header
writer.writerow(["ObjectKey", "ServerSideEncryption"])

for obj in response['Contents']:
    key = obj['Key']
    head_response = s3_client.head_object(Bucket=BUCKET_NAME, Key=key)
    encryption = head_response.get('ServerSideEncryption', 'None')
    
    # Write the object key and its encryption to the CSV
    writer.writerow([key, encryption])

What This Script Does:
	1.	Lists all objects in the specified S3 bucket.
	2.	For each object, retrieves its metadata and reads the ServerSideEncryption value.
	3.	Writes the results to CSV format, including a header row.

How to Use:
	1.	Ensure boto3 is installed and that you have valid AWS credentials.

pip install boto3


	2.	Save the script to a file, e.g., list_encryption_status.py.
	3.	Run the script:

python3 list_encryption_status.py > encryption_report.csv

This will write the CSV output to a file named encryption_report.csv.

You can then open encryption_report.csv with Excel, Google Sheets, or any other CSV-compatible tool.