Here is a **bash script** that sets up your project structure, writes the necessary Terraform and Lambda files, and initializes everything in a repository. 

Save this script as `setup_rest_api.sh` and run it.

---

### **Bash Script: `setup_rest_api.sh`**
```bash
#!/bin/bash

# Script to set up Terraform and Lambda REST API project
set -e

# Define directories and files
PROJECT_DIR="rest_api_project"
LAMBDA_DIR="$PROJECT_DIR/lambda"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

# Create project directories
echo "Creating project directories..."
mkdir -p $LAMBDA_DIR $TERRAFORM_DIR

# Create Lambda function file
echo "Creating Lambda function..."
cat << 'EOF' > $LAMBDA_DIR/get_users.js
const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.TABLE_NAME || 'UsersTable';

exports.handler = async (event) => {
    try {
        const params = {
            TableName: TABLE_NAME
        };

        const data = await dynamoDb.scan(params).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Users fetched", data: data.Items }),
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Error fetching users", error: error.message }),
        };
    }
};
EOF

# Create Terraform files
echo "Creating Terraform files..."
cat << 'EOF' > $TERRAFORM_DIR/main.tf
provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table
resource "aws_dynamodb_table" "users_table" {
  name           = "UsersTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "get_users" {
  function_name = "GetUsersFunction"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_users.handler"
  filename      = "lambda/get_users.zip"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "user_api" {
  name        = "UserAPI"
  description = "API for user management"
}

resource "aws_api_gateway_resource" "users_resource" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_rest_api.user_api.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "get_users_method" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.users_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_users_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.users_resource.id
  http_method             = aws_api_gateway_method.get_users_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_users.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_users.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  stage_name  = "dev"
  depends_on  = [aws_api_gateway_integration.get_users_integration]
}
EOF

# Initialize Node.js project for Lambda
echo "Initializing Node.js project..."
cd $LAMBDA_DIR
npm init -y
npm install aws-sdk
zip -r get_users.zip get_users.js node_modules

# Initialize Terraform
echo "Initializing Terraform..."
cd ../terraform
terraform init

# Finish
echo "Setup complete!"
echo "Navigate to $PROJECT_DIR to manage your project."
```

---

### **What the Script Does**
1. Creates a project folder structure:
   - `rest_api_project/`
     - `lambda/` (for Lambda code)
     - `terraform/` (for Terraform configurations)

2. Writes the necessary Lambda code (`get_users.js`) to the `lambda/` directory.

3. Sets up Terraform configurations (`main.tf`) for:
   - DynamoDB table
   - Lambda function
   - API Gateway

4. Initializes a Node.js project in the `lambda/` directory and zips the Lambda function for deployment.

5. Initializes Terraform in the `terraform/` directory.

---

### **How to Use**
1. Save the script as `setup_rest_api.sh`.
2. Run the script:
   ```bash
   chmod +x setup_rest_api.sh
   ./setup_rest_api.sh
   ```
3. Navigate to the `rest_api_project/terraform/` directory:
   ```bash
   cd rest_api_project/terraform
   terraform plan
   terraform apply
   ```
4. After applying, Terraform will output the API Gateway URL. Use it to test your API.

---

Would you like assistance testing or extending this setup?
