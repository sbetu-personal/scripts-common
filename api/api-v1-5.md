Below is a revised version of the code that ensures log group references use proper indexing when `count` is used. This prevents errors when switching between REST and WebSocket protocols, because Terraform won’t try to reference a resource that doesn’t exist (count=0). 

**Key Fix**:  
- Use `aws_cloudwatch_log_group.rest_logs[0].arn` and `aws_cloudwatch_log_group.websocket_logs[0].arn` instead of directly referencing `.arn` without indexing.  
- Because we are using `count` on the log group resources, we must index the resource references.

---

### Directory Structure

```
tf-apigateway/
  main.tf
  variables.tf
  outputs.tf
```

---

### main.tf

```hcl
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  is_rest      = var.protocol_type == "REST"
  is_websocket = var.protocol_type == "WEBSOCKET"
}

################################################################################
# REST API Resources (Private Endpoint)
################################################################################

resource "aws_api_gateway_rest_api" "rest_api" {
  count       = local.is_rest ? 1 : 0
  name        = var.name
  description = var.description

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = var.vpc_endpoint_ids
  }
}

resource "aws_api_gateway_resource" "rest_resource" {
  for_each   = local.is_rest ? var.rest_routes : {}
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  parent_id   = aws_api_gateway_rest_api.rest_api[0].root_resource_id
  path_part   = each.key
}

locals {
  rest_route_methods = local.is_rest ? flatten([
    for route_key, route_value in var.rest_routes : [
      for method_key, method_value in route_value.methods : {
        route_key    = route_key
        method_key   = method_key
        method_value = method_value
      }
    ]
  ]) : []
}

resource "aws_api_gateway_method" "rest_methods" {
  for_each    = { for i, v in local.rest_route_methods : "${v.route_key}||${v.method_key}" => v }
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  resource_id = aws_api_gateway_resource.rest_resource[each.value.route_key].id
  http_method = each.value.method_key
  authorization = try(each.value.method_value.authorization, var.authorization)
}

resource "aws_api_gateway_integration" "rest_integration" {
  for_each = { for k, v in aws_api_gateway_method.rest_methods : k => v }

  rest_api_id             = each.value.rest_api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  type                    = try(var.rest_routes[each.value.route_key].methods[each.value.http_method].integration.type, "HTTP")
  integration_http_method = try(var.rest_routes[each.value.route_key].methods[each.value.http_method].integration.http_method, "POST")
  uri                     = try(var.rest_routes[each.value.route_key].methods[each.value.http_method].integration.uri, var.integration_uri)
}

resource "aws_api_gateway_deployment" "rest_deployment" {
  count       = local.is_rest ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  depends_on = [
    aws_api_gateway_method.rest_methods,
    aws_api_gateway_integration.rest_integration
  ]
}

resource "aws_api_gateway_stage" "rest_stage" {
  count         = local.is_rest ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.rest_api[0].id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.rest_deployment[0].id

  access_log_settings {
    # Index the log group since it's created with count=...
    destination_arn = aws_cloudwatch_log_group.rest_logs[0].arn
    format          = var.access_log_format
  }

  cache_cluster_enabled = var.enable_caching
  cache_cluster_size    = var.cache_size
}

################################################################################
# WebSocket API Resources
#
# NOTE: WebSocket APIs currently only support REGIONAL endpoints, not PRIVATE.
################################################################################

module "websocket_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 2.0"

  count = local.is_websocket ? 1 : 0

  protocol_type      = "WEBSOCKET"
  name               = var.name
  enable_access_logs = true

  # Index the WebSocket log group
  access_log_settings = {
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.routeKey",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
    destination_arn = aws_cloudwatch_log_group.websocket_logs[0].arn
  }

  routes = var.websocket_routes

  domain_name         = var.domain_name
  create_domain_name  = true
  hosted_zone_name    = var.hosted_zone_name
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

### variables.tf

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

variable "rest_routes" {
  description = <<EOT
Map of REST routes with methods and integration details.
Example:
rest_routes = {
  "myresource" = {
    methods = {
      "GET" = {
        authorization = "NONE"
        integration = {
          type         = "HTTP"
          http_method  = "GET"
          uri          = "https://backend.example.com/get"
        }
      }
    }
  }
}
EOT
  type = map(object({
    methods = map(object({
      authorization = optional(string, "NONE")
      integration = object({
        type         = string
        http_method  = string
        uri          = string
      })
    }))
  }))
  default = {}
}

variable "websocket_routes" {
  description = <<EOT
Map of WebSocket routes with their integration settings.
Example:
websocket_routes = {
  "$connect" = {
    integration = {
      type = "AWS_PROXY"
      uri  = "arn:aws:lambda:us-east-1:123456789012:function:websocket-connect"
    }
  }
}
EOT
  type = map(object({
    integration = object({
      type = string
      uri  = string
    })
  }))
  default = {}
}

variable "authorization" {
  description = "Default authorization type for REST methods (when not specified in rest_routes)"
  type        = string
  default     = "NONE"
}

variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
  default     = "production"
}

variable "access_log_format" {
  description = "Format for the REST access logs"
  type        = string
  default     = jsonencode({
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
  description = "Cache cluster size for the REST API"
  type        = string
  default     = "0.5"
}

variable "integration_uri" {
  description = "Default Integration endpoint URI for REST API methods (if not specified in rest_routes)"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Custom domain name for the WebSocket API"
  type        = string
  default     = null
}

variable "hosted_zone_name" {
  description = "Hosted zone for the WebSocket domain"
  type        = string
  default     = null
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs for the private REST API"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}
```

---

### outputs.tf

```hcl
output "rest_api_id" {
  value       = local.is_rest ? aws_api_gateway_rest_api.rest_api[0].id : null
  description = "The ID of the REST API"
}

output "rest_stage_invoke_url" {
  value       = local.is_rest ? aws_api_gateway_stage.rest_stage[0].invoke_url : null
  description = "The Invoke URL of the REST API"
}

output "websocket_api_id" {
  value       = local.is_websocket ? module.websocket_api[0].api_id : null
  description = "The ID of the WebSocket API"
}
```

---

### Example Usage

```hcl
module "api_gateway" {
  source = "./tf-apigateway"

  protocol_type = "REST"
  name          = "MyPrivateRESTAPI"
  description   = "My Private REST API Gateway"

  rest_routes = {
    "myresource" = {
      methods = {
        "GET" = {
          authorization = "NONE"
          integration = {
            type         = "HTTP"
            http_method  = "GET"
            uri          = "https://backend.example.com/get"
          }
        }
      }
    }
  }

  # If you have VPC endpoints for private API:
  vpc_endpoint_ids = ["vpce-0abc123def456ghij"]

  tags = {
    Environment = "Production"
  }
}
```

**Note:**  
- When `protocol_type = "WEBSOCKET"`, the REST resources and their log group are not created, and vice versa. This avoids referencing non-existent resources.  
- The indexing `[0]` ensures that if the count is zero, Terraform does not try to reference a missing element because that resource block won't even be created.
