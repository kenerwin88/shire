# Roles
resource "aws_iam_role" "codepipeline_service_role" {
  name               = "CodePipelineServiceRole"
  assume_role_policy = file("iam/roles/CodePipelineServiceRole.json")
}
resource "aws_iam_role" "eks_service_role" {
  name               = "EksServiceRole"
  assume_role_policy = file("iam/roles/EKSServiceRole.json")
}

# Policies
resource "aws_iam_role_policy" "codepipeline_service_policy" {
  name   = "CodePipelineServicePolicy"
  role   = aws_iam_role.codepipeline_service_role.name
  policy = file("iam/policies/CodePipelineServicePolicy.json")
}
resource "aws_iam_role_policy" "eks_service_policy" {
  name   = "EKSServicePolicy"
  role   = aws_iam_role.eks_service_role.id
  policy = file("iam/policies/EKSServicePolicy.json")
}
