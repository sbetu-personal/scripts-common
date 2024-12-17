Below is an enhanced Python script that:
	1.	By default, lists all S3 buckets in the AWS account and retrieves object encryption status for each.
	2.	If a bucket list file is provided (via --buckets <filename>), it only checks those buckets in the file.

Features:
	•	Uses argparse for command-line options.
	•	If no buckets file is given, it retrieves and checks all buckets in the account.
	•	If a buckets file is given, it reads the bucket names from that file (one per line).
	•	Outputs results to CSV format, printing to stdout by default. You can redirect to a file if needed.

Requirements:
	•	boto3 installed (pip install boto3)
	•	AWS credentials configured
	•	jq no longer needed since we’re using Python directly.

Usage Examples:
	•	Check all buckets in the account:

python3 s3_encryption_report.py > all_buckets_report.csv


	•	Check only buckets specified in my_buckets.txt:

python3 s3_encryption_report.py --buckets my_buckets.txt > selected_buckets_report.csv



Script (s3_encryption_report.py):

import boto3
import csv
import sys
import argparse

def list_all_buckets(s3_client):
    response = s3_client.list_buckets()
    buckets = [b['Name'] for b in response.get('Buckets', [])]
    return buckets

def list_objects_in_bucket(s3_client, bucket_name):
    # Lists all objects in the bucket. May need pagination if many objects.
    objects = []
    paginator = s3_client.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=bucket_name):
        for obj in page.get('Contents', []):
            objects.append(obj['Key'])
    return objects

def check_bucket_encryption(s3_client, bucket_name, writer):
    # List all objects and determine their encryption status
    try:
        objects = list_objects_in_bucket(s3_client, bucket_name)
        # If no objects found, write a line indicating this (optional)
        if not objects:
            writer.writerow([bucket_name, "", "No objects in bucket"])
            return

        for key in objects:
            head_response = s3_client.head_object(Bucket=bucket_name, Key=key)
            encryption = head_response.get('ServerSideEncryption', 'None')
            writer.writerow([bucket_name, key, encryption])

    except s3_client.exceptions.NoSuchBucket:
        # Bucket may not exist or might have been deleted
        writer.writerow([bucket_name, "", "Bucket does not exist or is not accessible"])
    except Exception as e:
        # Catch all other exceptions for logging
        writer.writerow([bucket_name, "", f"Error retrieving objects: {e}"])

def main():
    parser = argparse.ArgumentParser(description="Generate an S3 encryption report for one or more buckets.")
    parser.add_argument("--buckets", help="Path to a text file containing a list of buckets to check (one per line). If not provided, all buckets will be checked.")
    args = parser.parse_args()

    s3_client = boto3.client('s3')

    if args.buckets:
        # Read buckets from the provided file
        with open(args.buckets, 'r') as f:
            buckets = [line.strip() for line in f if line.strip()]
    else:
        # No buckets file provided, list all buckets in the account
        buckets = list_all_buckets(s3_client)

    writer = csv.writer(sys.stdout, lineterminator='\n')
    writer.writerow(["BucketName", "ObjectKey", "ServerSideEncryption"])

    for bucket in buckets:
        check_bucket_encryption(s3_client, bucket, writer)

if __name__ == "__main__":
    main()

How This Works:
	•	main() parses optional arguments.
	•	If --buckets is provided, it reads bucket names from the file. Otherwise, it lists all buckets in the account.
	•	For each bucket, it:
	•	Lists all objects (using a paginator to handle large buckets).
	•	Retrieves ServerSideEncryption for each object.
	•	Writes the results to CSV (BucketName, ObjectKey, ServerSideEncryption).

If you have a large number of buckets or objects, this script might take some time. For extremely large buckets, consider using S3 Inventory or other batch methods for scalability.