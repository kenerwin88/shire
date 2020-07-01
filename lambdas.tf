data "archive_file" "helmLambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/helm"
  output_path = "${path.module}/lambdas/helm.zip"
}

resource "aws_lambda_function" "helm_lambda" {
  filename         = "./lambdas/helm.zip"
  function_name    = "helm"
  role             = aws_iam_role.eksAdminRole.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.helmLambda.output_base64sha256
  runtime          = "provided"
  timeout          = 360
  layers = ["arn:aws:lambda:us-east-1:983509570635:layer:bash:1"]
}

