resource "aws_servicecatalog_portfolio" "example" {
  name          = "SageMakerStudioEMRPortfolio"
  description   = "Portfolio for SageMaker Studio Classic EMR Templates"
  provider_name = "AWS"
}

resource "aws_servicecatalog_product" "example" {
  name             = "EMRClusterProduct"
  owner            = "AWS"
  type             = "CLOUD_FORMATION_TEMPLATE"
  description      = "Product to provision EMR Clusters from SageMaker Studio Classic"
  distributor      = "AWS"
  support_description = "Support provided by AWS"
  support_email    = "support@example.com"
  support_url      = "http://support.example.com"

  provisioning_artifact_parameters {
    name = "v1"  
    type = "CLOUD_FORMATION_TEMPLATE"  
    template_url = "https://raw.githubusercontent.com/debnsuma/sagemaker-studio-emr-spark/main/code/CFN-SagemakerEMRNoAuthProductWithStudio-v3.yaml"
  }

  tags = {
    "sagemaker:studio-visibility:emr" = "true"
  }
}

resource "aws_servicecatalog_product_portfolio_association" "example" {
  portfolio_id = aws_servicecatalog_portfolio.example.id
  product_id   = aws_servicecatalog_product.example.id
}


resource "aws_servicecatalog_principal_portfolio_association" "poc_role_association" {
  portfolio_id   = aws_servicecatalog_portfolio.example.id
  principal_arn  = aws_iam_role.poc_role.arn
  principal_type = "IAM"
}