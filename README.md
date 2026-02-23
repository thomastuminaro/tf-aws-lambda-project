Project idea : 

> Run a Python Lambda function interacting with an SQL database (MySQL) running on AWS 
> The Python function creates following endpoint : 
> /admin : should only be accessible for a user having a custom role created - this allows to list all entries in the database
> /add-user : accessible for users having the specific role - allows to create users
> /view-users : allows to list that a specific user created using API 

> The API is available behind API Gateway service to implement security features 
> Control access to API using IAM authorizers

> The database will be hosted on AWS 
> To limit costs, only one DB will run 
> Manage DB password with secrets manager 
> Set up RDS proxy to manage connections to DB 

> Network : will need a custom VPC with two subnets for the DB  - need different AZs
> Also need 2 subnets in 2 AZs for the Lambda function 
> Need security groups :
> SQL should only allow traffic to Lambda function (all) and from Lambda function to 3306 
> Lambda only allows traffic to 3306 SQL and all traffic from API gateway 

> Implement logging with CloudWatch Logs : each API call should get logged
> if user tries to login to admin interface and doesn't have access, should generate error in logs and trigger SNS mail notification
> Monitoring should be available to check all components in CloudWatch 

#### GATEWAY API 

Acts as "front door" to access applications 
=> can help with state, authentication, release deployment
=> logging, monitoring 

Idea is : create the Gateway and add integration for the Lambda function 

Logging : need to create a Cloud Watch log group 

Authorization : will need to set HTTP API route authorization type to IAM 
=> Can create IAM policies with permissions to execute API calls
=> https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html 

tf resources : 
aws_apigatewayv2_api : main API 
aws_apigatewayv2_integration : integration of Lambda function
apigatewayv2_route : route traffic to Lambda function 
apigatewayv2_integration_response : handles Lambda errors 

Handle Lambda errors : https://docs.amazonaws.cn/en_us/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html 

Create Lambda function in Python with code 

As default : no access logging + no CloudWatch Log Group created 

curl --aws-sigv4 "aws:amz:eu-west-3:execute-api" --user "$(aws configure get aws_access_key_id):$(aws configure get aws_secret_access_key)" "https://6qp3zeqgh0.execute-api.eu-west-3.amazonaws.com/test/admin/" --output -

curl --aws-sigv4 "aws:amz:eu-west-3:execute-api" --user "accesskey:secrettkey" "https://6qp3zeqgh0.execute-api.eu-west-3.amazonaws.com/test/admin/" --output -

Code : using path key from event dict get("path")