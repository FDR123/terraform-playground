locals {
  lambdas = {
    lambda1 = {
      handler = "handler.handler"
      runtime = "nodejs18.x"
      path    = "../lambdas/user_api"
    }
  }
}
data "template_file" "openapi" {
  for_each = local.lambdas

  template = file("${each.value.path}/openapi.yml")

  vars = {
    lambda_arn             = aws_lambda_function.lambdas[each.key].arn
    lambda_integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambdas[each.key].arn}/invocations"
  }

}


resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "lambda-deployment-fdr"

  tags = var.common_tags
}


resource "aws_api_gateway_rest_api" "api" {
  for_each = local.lambdas

  name        = "${each.key}_ApiGateway"
  description = "API Gateway for ${each.key} Lambda function"
  body        = data.template_file.openapi[each.key].rendered
  tags        = var.common_tags
}


resource "aws_api_gateway_resource" "resource" {
  for_each = local.lambdas

  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  parent_id   = aws_api_gateway_rest_api.api[each.key].root_resource_id
  path_part   = each.key
}


resource "aws_iam_policy" "lambda_vpc_policy" {
  name   = "LambdaVPCPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = aws_iam_policy.lambda_vpc_policy.id
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_function" "lambdas" {
  for_each      = local.lambdas
  function_name = each.key
  handler       = each.value.handler
  runtime       = each.value.runtime
  role          = aws_iam_role.lambda_execution_role.arn

  filename = "${each.value.path}/package.zip"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }
  tags = var.common_tags
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = local.lambdas

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdas[each.key].function_name
  principal     = "apigateway.amazonaws.com"



  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api[each.key].id}/*/*/*"
}

data "aws_caller_identity" "current" {}


resource "aws_api_gateway_deployment" "deployment" {
  for_each = local.lambdas

  rest_api_id = aws_api_gateway_rest_api.api[each.key].id

  # This triggers a new deployment whenever there's a change in the API Gateway
  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_api_gateway_rest_api.api[each.key]),
      jsonencode(aws_api_gateway_resource.resource[each.key])
    ])))
  }

  depends_on = [
    aws_api_gateway_resource.resource
  ]
}

resource "aws_api_gateway_stage" "stage" {
  for_each = local.lambdas

  deployment_id = aws_api_gateway_deployment.deployment[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  stage_name    = "prod"
}
