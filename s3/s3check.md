#!/usr/bin/env bash
set -euo pipefail

# Replace with your actual bucket name
BUCKET_NAME="<your-bucket-name>"

# If the bucket is not in your default region, uncomment and set the region:
# REGION="us-west-2"
# Add --region "$REGION" to the aws commands if needed.

# List objects in the bucket and read their keys line by line
aws s3api list-objects --bucket "$BUCKET_NAME" \
    --query "Contents[].Key" \
    --output text ${REGION:+--region "$REGION"} | \
while IFS= read -r key; do
  echo "Checking object: $key"

  # Get object metadata in JSON format
  obj_metadata=$(aws s3api head-object \
    --bucket "$BUCKET_NAME" \
    --key "$key" \
    --output json \
    ${REGION:+--region "$REGION"} 2>/dev/null || true)

  # If no metadata was returned, object might not exist or you lack permissions
  if [ -z "$obj_metadata" ]; then
    echo "Warning: Could not retrieve metadata for $key"
    continue
  fi

  # Extract the ServerSideEncryption field from the JSON
  encryption=$(echo "$obj_metadata" | jq -r '.ServerSideEncryption // "None"')

  if [ "$encryption" = "None" ]; then
    echo "Unencrypted object: $key"
  else
    echo "Encrypted object: $key with SSE: $encryption"
  fi
done