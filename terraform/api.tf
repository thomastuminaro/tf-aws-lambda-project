# Need to enable logging for API GW 

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.common_tags.Project}-apigw"
  protocol_type = "HTTP"
  description   = "Will manage connections to Lambda function."
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  description            = "Lambda function integration."
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "root" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_deployment" "lambda" {
  api_id      = aws_apigatewayv2_api.main.id
  description = "Main deployment for the Lambda function API."

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.lambda),
      jsonencode(aws_apigatewayv2_route.root),
    ])))
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id        = aws_apigatewayv2_api.main.id
  name          = "lambda"
  deployment_id = aws_apigatewayv2_deployment.lambda.id
  auto_deploy   = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
  route_settings {
    route_key     = aws_apigatewayv2_route.root.route_key
    logging_level = "INFO"
  }
}