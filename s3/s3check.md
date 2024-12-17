Below is a revised version of the script. The main adjustments are:
	•	Ensuring we correctly handle objects that do not have the ServerSideEncryption field. If it’s not present, the AWS CLI returns None when using --query "ServerSideEncryption" with --output text.
	•	Removing the NoneType check as it’s unnecessary. If an object is unencrypted, the returned value should be None.

Updated Script:

#!/usr/bin/env bash

BUCKET_NAME="<bucket-name>"

aws s3api list-objects --bucket "$BUCKET_NAME" --query "Contents[].Key" --output text | while read -r key; do
  # Query the object's ServerSideEncryption field
  encryption=$(aws s3api head-object \
    --bucket "$BUCKET_NAME" \
    --key "$key" \
    --query "ServerSideEncryption" \
    --output text 2>/dev/null)

  # If ServerSideEncryption is None, the object is unencrypted.
  if [ "$encryption" = "None" ]; then
    echo "Unencrypted object: $key"
  else
    # For encrypted objects, $encryption should be something like 'AES256' or 'aws:kms'
    echo "Encrypted object: $key with SSE: $encryption"
  fi
done

What This Script Does:
	•	Lists all objects in the specified S3 bucket.
	•	For each object, it retrieves its server-side encryption status using head-object.
	•	If the ServerSideEncryption attribute is None, it prints that the object is unencrypted.
	•	If it is something else (like AES256 or aws:kms), it prints the encryption type.

Common Issues to Consider:
	•	If the bucket is empty or you don’t have the right permissions (such as missing s3:GetObject or s3:HeadObject), the script may fail or return no results.
	•	For very large buckets, the script might be slow. Consider using S3 Inventory for large-scale assessments.
	•	Make sure you have the latest AWS CLI installed and that your credentials and region configurations are correct.