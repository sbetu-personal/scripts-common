To keep everything in **one Terraform module** for managing both REST and WebSocket APIs with the ability to choose between them dynamically (similar to how it's handled in the `terraform-aws-apigateway-v2` module), here's an updated solution. We'll use a **single repository** with dynamic logic to handle the protocol type (REST or WebSocket) based on a variable.

---

### **Unified Terraform Module**

This module will allow you to specify `protocol_type` as `REST` or `WEBSOCKET` to configure either REST or WebSocket APIs. The module will dynamically create the necessary resources based on the chosen protocol.

---

#### **Directory Structure**
```
tf-apigateway/
  main.tf
  variables.tf
  outputs.tf
```

---

#### **main.tf**
```hcl
# Determine whether to create REST or WebSocket APIs
locals {
  is_rest      = var.protocol_type == "REST"
  is_websocket = var.protocol_type == "WEBSOCKET"
}

################################################################################
# REST API Resources
################################################################################

resource "aws_api_gateway_rest_api" "rest_api" {
  count       = local.is_rest ? 1 : 0
  name        = var.name
  description = var.description
}

resource "aws_api_gateway_resource" "rest_resource" {
  count      = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "rest_method" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.rest_resource[0].id
  http_method = var.http_method
  authorization = var.authorization
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  depends_on  = [aws_api_gateway_method.rest_method]
}

resource "aws_api_gateway_stage" "rest_stage" {
  count        = local.is_rest ? 1 : 0
  rest_api_id  = aws_api_gateway_rest_api.rest_api[0].id
  stage_name   = var.stage_name
  deployment_id = aws_api_gateway_deployment.rest_deployment[0].id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.rest_logs.arn
    format          = var.access_log_format
  }

  cache_cluster_enabled = var.enable_caching
  cache_cluster_size    = var.cache_size
}

resource "aws_api_gateway_integration" "rest_integration" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.rest_resource[0].id
  http_method = aws_api_gateway_method.rest_method[0].http_method
  type        = "HTTP"
  integration_http_method = "POST"
  uri         = var.integration_uri
}

################################################################################
# WebSocket API Resources
################################################################################

module "websocket_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 2.0"

  count = local.is_websocket ? 1 : 0

  protocol_type     = "WEBSOCKET"
  name              = var.name
  enable_access_logs = true

  access_log_settings = {
    format = jsonencode({
      requestId             = "$context.requestId",
      ip                    = "$context.identity.sourceIp",
      requestTime           = "$context.requestTime",
      httpMethod            = "$context.httpMethod",
      resourcePath          = "$context.resourcePath",
      status                = "$context.status",
      protocol              = "$context.protocol",
      responseLength        = "$context.responseLength"
    })
    destination_arn = aws_cloudwatch_log_group.websocket_logs.arn
  }

  routes = {
    "$connect" = {
      integration = {
        type = "AWS_PROXY"
        uri  = "arn:aws:lambda:us-east-1:123456789012:function:websocket-connect"
      }
    }
    "$disconnect" = {
      integration = {
        type = "AWS_PROXY"
        uri  = "arn:aws:lambda:us-east-1:123456789012:function:websocket-disconnect"
      }
    }
  }

  domain_name        = var.domain_name
  create_domain_name = true
  hosted_zone_name   = var.hosted_zone_name
  domain_name_options = {
    minimum_tls_version = "TLS_1_2"
  }

  tags = var.tags
}

################################################################################
# Shared Resources
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
```

---

#### **variables.tf**
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
  description = "HTTP method for the API (e.g., GET, POST)"
  type        = string
  default     = "GET"
}

variable "authorization" {
  description = "Authorization type (e.g., NONE, AWS_IAM)"
  type        = string
  default     = "NONE"
}

variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
  default     = "production"
}

variable "access_log_format" {
  description = "Format for the access logs"
  type        = string
  default     = jsonencode({
    requestId   = "$context.requestId",
    ip          = "$context.identity.sourceIp",
    requestTime = "$context.requestTime",
    httpMethod  = "$context.httpMethod",
    resourcePath = "$context.resourcePath",
    status      = "$context.status",
    protocol    = "$context.protocol"
  })
}

variable "enable_caching" {
  description = "Enable caching for the API"
  type        = bool
  default     = false
}

variable "cache_size" {
  description = "Cache cluster size"
  type        = string
  default     = "0.5"
}

variable "integration_uri" {
  description = "Integration endpoint URI for REST API"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the WebSocket API"
  type        = string
}

variable "hosted_zone_name" {
  description = "Hosted zone for the WebSocket domain"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}
```

---

#### **outputs.tf**
```hcl
output "rest_api_id" {
  value       = aws_api_gateway_rest_api.rest_api[0].id
  description = "The ID of the REST API"
  condition   = local.is_rest
}

output "websocket_api_id" {
  value       = module.websocket_api[0].api_id
  description = "The ID of the WebSocket API"
  condition   = local.is_websocket
}
```

---

### **How to Use This Unified Module**

#### Example Usage
```hcl
module "api_gateway" {
  source = "./tf-apigateway"

  protocol_type   = "REST" # Change to "WEBSOCKET" to create WebSocket API
  name            = "MyAPI"
  description     = "My API Gateway"
  resource_path   = "myresource"
  http_method     = "POST"
  integration_uri = "https://backend.example.com/api"

  domain_name      = "websocket.example.com"
  hosted_zone_name = "example.com"

  enable_caching = true
  cache_size     = "1.6"

  tags = {
    Environment = "Production"
  }
}
```

---

### **Advantages of This Approach**
1. **Single Module**: Both REST and WebSocket APIs are handled in one module, and the `protocol_type` determines the behavior dynamically.
2. **CBC Compliance**:
   - WebSocket uses TLS 1.2, logging, and private integrations.
   - REST API supports logging, HTTPS integration, and caching.
3. **Flexibility**: Easily switch between REST and WebSocket by changing `protocol_type`.

Let me know if you need further adjustments!