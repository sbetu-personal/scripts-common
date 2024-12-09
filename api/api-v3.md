This code includes all the logic for handling REST and WebSocket APIs, enforcing TLS 1.2, disallowing Cognito authorizers, validating Lambda authorizer ARNs, and supporting optional private endpoints and caching. Just place these files in a directory (e.g., `tf-apigateway/`) and reference it as your module source.

---

### `main.tf`

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  is_rest        = var.protocol_type == "REST"
  is_websocket   = var.protocol_type == "WEBSOCKET"
  is_lambda_auth = var.authorization == "LAMBDA"

  # Determine effective account ID to validate Lambda authorizers against.
  # If cma_aws_account_id is provided, use that; otherwise, use the current account.
  effective_account_id = var.cma_aws_account_id != "" ? var.cma_aws_account_id : data.aws_caller_identity.current.account_id
}

resource "null_resource" "validate_lambda_authorizer" {
  count = local.is_lambda_auth && length(var.lambda_authorizer_arn) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      arn="${var.lambda_authorizer_arn}"
      account_id="${local.effective_account_id}"
      if ! echo "$arn" | grep -q ":$account_id:function:"; then
        echo "Invalid Lambda Authorizer ARN! It must be from account: ${account_id}"
        exit 1
      fi
    EOF
  }
}

################################################################################
# REST API Resources
################################################################################

resource "aws_api_gateway_rest_api" "rest_api" {
  count       = local.is_rest ? 1 : 0
  name        = var.name
  description = var.description

  dynamic "endpoint_configuration" {
    for_each = var.enable_private_endpoint ? toset(["PRIVATE"]) : toset([])
    content {
      types = [endpoint_configuration.key]
    }
  }

  # We allow policy updates dynamically if provided
  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_api_gateway_resource" "rest_resource" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "rest_method" {
  count         = local.is_rest ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  resource_id   = aws_api_gateway_resource.rest_resource[0].id
  http_method   = var.http_method
  authorization = var.authorization
}

resource "aws_api_gateway_integration" "rest_integration" {
  count                  = local.is_rest ? 1 : 0
  rest_api_id            = aws_api_gateway_rest_api.rest_api[0].id
  resource_id            = aws_api_gateway_resource.rest_resource[0].id
  http_method            = aws_api_gateway_method.rest_method[0].http_method
  type                   = "HTTP"
  integration_http_method = "POST"
  uri                    = var.integration_uri

  # If using a VPC link for private integration
  vpc_link_id = var.use_vpc_link ? var.vpc_link_id : null
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  depends_on  = [aws_api_gateway_integration.rest_integration]
}

resource "aws_api_gateway_stage" "rest_stage" {
  count         = local.is_rest ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.rest_deployment[0].id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.rest_logs.arn
    format          = var.access_log_format
  }

  cache_cluster_enabled = var.enable_caching
  cache_cluster_size    = var.cache_size
}

resource "aws_api_gateway_domain_name" "rest_domain" {
  count           = local.is_rest && var.domain_name != "" && var.certificate_arn != "" ? 1 : 0
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
  security_policy = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "rest_base_path_mapping" {
  count       = local.is_rest && length(aws_api_gateway_domain_name.rest_domain) > 0 ? 1 : 0
  domain_name = aws_api_gateway_domain_name.rest_domain[0].domain_name
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  stage_name  = var.stage_name
}

################################################################################
# WebSocket API Resources
################################################################################

module "websocket_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 2.0"

  count = local.is_websocket ? 1 : 0

  protocol_type      = "WEBSOCKET"
  name               = var.name
  enable_access_logs = true

  access_log_settings = {
    format = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      requestTime     = "$context.requestTime",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      protocol        = "$context.protocol",
      responseLength  = "$context.responseLength"
    })
    destination_arn = aws_cloudwatch_log_group.websocket_logs.arn
  }

  routes = {
    "$connect" = {
      integration = {
        type = "AWS_PROXY"
        uri  = "arn:aws:lambda:us-east-1:${local.effective_account_id}:function:websocket-connect"
      }
    }
    "$disconnect" = {
      integration = {
        type = "AWS_PROXY"
        uri  = "arn:aws:lambda:us-east-1:${local.effective_account_id}:function:websocket-disconnect"
      }
    }
  }

  domain_name         = var.domain_name
  create_domain_name  = length(var.domain_name) > 0 && var.certificate_arn != ""
  hosted_zone_name    = var.hosted_zone_name
  domain_name_options = {
    minimum_tls_version = "TLS_1_2"
  }

  tags = var.tags
}

################################################################################
# Shared Logging Resources
################################################################################

resource "aws_cloudwatch_log_group" "rest_logs" {
  count             = local.is_rest ? 1 : 0
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "websocket_logs" {
  count             = local.is_websocket ? 1 : 0
  name              = "/aws/apigateway/websocket"
  retention_in_days = 30
}

################################################################################
# Optional Resource Policy for REST API
################################################################################

resource "aws_api_gateway_rest_api_policy" "rest_policy" {
  count      = (local.is_rest && var.rest_api_policy_json != "") ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  policy      = var.rest_api_policy_json
}

################################################################################
# API Gateway Account configuration for CloudWatch Logging (optional)
################################################################################

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}
```

---

### `variables.tf`

```hcl
variable "protocol_type" {
  description = "Type of API Gateway (REST or WEBSOCKET)"
  type        = string
  default     = "REST"
}

variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "Managed by Terraform"
}

variable "resource_path" {
  description = "Path for the REST API resource"
  type        = string
  default     = "myresource"
}

variable "http_method" {
  description = "HTTP method for the REST API (e.g., GET, POST)"
  type        = string
  default     = "GET"
}

variable "authorization" {
  description = "Authorization type (NONE, AWS_IAM, LAMBDA). Cognito user pools not allowed."
  type        = string
  default     = "NONE"
  validation {
    condition     = !(contains(["COGNITO_USER_POOLS"], var.authorization))
    error_message = "Cognito User Pool authorizers are not allowed."
  }
}

variable "lambda_authorizer_arn" {
  description = "ARN of the Lambda Authorizer function if authorization=LAMBDA"
  type        = string
  default     = ""
}

variable "cma_aws_account_id" {
  description = "If provided, enforce Lambda Authorizers must come from this account. If empty, uses current account."
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
  default     = "production"
}

variable "access_log_format" {
  description = "Format for the access logs"
  type        = string
  default = jsonencode({
    requestId    = "$context.requestId",
    ip           = "$context.identity.sourceIp",
    requestTime  = "$context.requestTime",
    httpMethod   = "$context.httpMethod",
    resourcePath = "$context.resourcePath",
    status       = "$context.status",
    protocol     = "$context.protocol"
  })
}

variable "enable_caching" {
  description = "Enable caching for the REST API"
  type        = bool
  default     = false
}

variable "cache_size" {
  description = "Cache cluster size"
  type        = string
  default     = "0.5"
}

variable "integration_uri" {
  description = "Integration endpoint URI for REST API. Should be HTTPS or use a VPC link."
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the API (REST or WebSocket)"
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = "Hosted zone for the custom domain"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}

variable "enable_private_endpoint" {
  description = "If true, configure the REST API as a PRIVATE endpoint"
  type        = bool
  default     = false
}

variable "use_vpc_link" {
  description = "If true, use a VPC link integration for private endpoints"
  type        = bool
  default     = false
}

variable "vpc_link_id" {
  description = "ID of the existing VPC Link to use if use_vpc_link is true"
  type        = string
  default     = ""
}

variable "rest_api_policy_json" {
  description = "JSON string for the REST API resource policy. If empty, no policy is applied."
  type        = string
  default     = ""
}

variable "cloudwatch_role_arn" {
  description = "IAM Role ARN for API Gateway to write CloudWatch logs"
  type        = string
  default     = ""
}
```

---

### `outputs.tf`

```hcl
output "rest_api_id" {
  value       = local.is_rest ? aws_api_gateway_rest_api.rest_api[0].id : null
  description = "The ID of the REST API"
}

output "websocket_api_id" {
  value       = local.is_websocket ? module.websocket_api[0].api_id : null
  description = "The ID of the WebSocket API"
}
```

---

### Example Usage (REST API)

```hcl
module "api_gateway_rest" {
  source = "./tf-apigateway"

  protocol_type     = "REST"
  name              = "MyRESTAPI"
  description       = "My REST API Gateway"
  resource_path     = "myresource"
  http_method       = "POST"
  integration_uri   = "https://backend.example.com/api"
  stage_name        = "prod"
  
  # Authorization: For example, Lambda authorizer in the same account
  authorization        = "LAMBDA"
  lambda_authorizer_arn = "arn:aws:lambda:us-east-1:111222333444:function:my-authorizer"
  
  # This will default to using current account since cma_aws_account_id is not set

  enable_caching       = true
  cache_size           = "1.6"
  domain_name          = "api.example.com"
  certificate_arn      = "arn:aws:acm:us-east-1:111222333444:certificate/abc123..."

  tags = {
    Environment = "Production"
  }
}
```

### Example Usage (WebSocket API)

```hcl
module "api_gateway_ws" {
  source = "./tf-apigateway"

  protocol_type    = "WEBSOCKET"
  name             = "MyWebSocketAPI"
  description      = "My WebSocket API Gateway"
  domain_name      = "ws.example.com"
  hosted_zone_name = "example.com"
  certificate_arn  = "arn:aws:acm:us-east-1:111222333444:certificate/xyz789..."

  # Defaults to using current account for validation of Lambda authorizers
  # In this example, we rely on the WebSocket defaults set inside the module
  # for $connect/$disconnect routes.

  tags = {
    Environment = "Production"
  }
}
```

---

This full solution uses `cma_aws_account_id` as requested, defaults to using the current AWS account if not provided, and aligns with the CBC requirements.
