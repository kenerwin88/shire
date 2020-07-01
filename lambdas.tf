resource "aws_lambda_function" "helm_lambda" {
  filename         = "./helmLambda.zip"
  function_name    = "helm"
  role             = aws_iam_role.eksAdminRole.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("./helmLambda.zip")
  runtime          = "provided"
  timeout          = 360
  layers = ["arn:aws:lambda:us-east-1:983509570635:layer:bash:1"]
}

