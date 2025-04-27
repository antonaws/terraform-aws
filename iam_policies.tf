resource "aws_iam_policy" "terraform_consolidated_policy" {
  name        = "terraform_consolidated_admin_policy"
  path        = "/"
  description = "Consolidated Terraform admin permissions for KMS, S3, RDS, and EC2."

  policy = file("${path.module}/terraform-consolidated-policy.json")
}

resource "aws_iam_user_policy_attachment" "terraform_consolidated_attachment" {
  user       = "container"
  policy_arn = aws_iam_policy.terraform_consolidated_policy.arn
}
