#!/usr/bin/env bash

BUCKET_NAME="<bucket-name>"

# List all object keys from the bucket
aws s3api list-objects --bucket "$BUCKET_NAME" --query "Contents[].Key" --output text | \
while IFS= read -r key; do
  # Retrieve the ServerSideEncryption attribute of the object
  encryption=$(aws s3api head-object \
    --bucket "$BUCKET_NAME" \
    --key "$key" \
    --query "ServerSideEncryption" \
    --output text 2>/dev/null)

  # Check the value of ServerSideEncryption
  if [ "$encryption" = "None" ]; then
    # No server-side encryption is applied
    echo "Unencrypted object: $key"
  elif [ "$encryption" = "AES256" ] || [ "$encryption" = "aws:kms" ]; then
    # The object is encrypted with AES256 or KMS
    echo "Encrypted object: $key with SSE: $encryption"
  else
    # If no value is returned or something else unexpected occurs
    # This could mean the object is unencrypted or inaccessible
    echo "Object: $key - No SSE field returned. Possibly unencrypted."
  fi
done