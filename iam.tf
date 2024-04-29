// BEGIN: Create a poc role
	resource "aws_iam_role" "poc_role" {
	name = "poc_role"
	path = "/"
	assume_role_policy = data.aws_iam_policy_document.poc_role.json
	managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"]
}

  

data "aws_iam_policy_document" "poc_role" {
	statement {
		actions = ["sts:AssumeRole"]
		principals {
			type = "Service"
			identifiers = ["sagemaker.amazonaws.com"]
		}
	}
}

resource "aws_iam_policy" "datascientists_sagemaker_policy" {
  name        = "DataScientistsSageMakerAccess"
  description = "Access to list SageMaker domains for data scientists"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   : [
          "sagemaker:ListDomains",
          "sagemaker:DescribeDomain",
          "sagemaker:ListUserProfiles",
          "sagemaker:DescribeUserProfile",
          "sagemaker:ListApps",
          "sagemaker:DescribeApp",
          "sagemaker:CreatePresignedDomainUrl"
        ],
        Effect   : "Allow",
        Resource : "*"
      },
    ]
  })
}


resource "aws_iam_policy_attachment" "datascientists_sagemaker_attachment" {
  name       = "DataScientistsSageMakerPolicyAttachment"
  groups     = ["datascientists"]
  policy_arn = aws_iam_policy.datascientists_sagemaker_policy.arn
}



resource "aws_iam_policy" "sagemaker_studio_control" {
  name        = "SageMakerStudioControl"
  description = "Restrictive policy for managing SageMaker Studio instances"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          // Hypothetical actions for starting and stopping Studio apps
          "sagemaker:StartApp",
          "sagemaker:StopApp"
        ],
        Resource: "*"
      },
      {
        Effect: "Deny",
        Action: [
          // Hypothetical action for creating Studio apps
          "sagemaker:CreateApp"
        ],
        Resource: "*",
        "Condition": {
        "ForAnyValue:StringNotLike": {
            "sagemaker:InstanceTypes": [
                "ml.t3.medium"
            ]
        }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "sagemaker_studio_control_attachment" {
  name       = "SageMakerStudioControlAttachment"
  roles      = [aws_iam_role.poc_role.name]
  policy_arn = aws_iam_policy.sagemaker_studio_control.arn
}


resource "aws_iam_policy" "sagemaker_emr_access" {
  name   = "SageMakerEMRAccess"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPresignedUrl"
        Effect   = "Allow"
        Action   = [
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:ListInstanceGroups",
          "elasticmapreduce:CreatePersistentAppUI",
          "elasticmapreduce:DescribePersistentAppUI",
          "elasticmapreduce:GetPersistentAppUIPresignedURL",
          "elasticmapreduce:GetOnClusterAppUIPresignedURL",
        ]
        Resource = [ 
          "arn:aws:elasticmapreduce:ca-central-1:*:cluster/*"
        ]
      },
      {
        Sid      = "AllowClusterDetailsDiscovery"
        Effect   = "Allow"
        Action   = [
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:ListInstances",
          "elasticmapreduce:ListInstanceGroups",
          "elasticmapreduce:DescribeSecurityConfiguration",
        ]
        Resource = [
          "arn:aws:elasticmapreduce:ca-central-1:*:cluster/*"
        ]
      },
      {
        Sid      = "AllowClusterDiscovery"
        Effect   = "Allow"
        Action   = [
          "elasticmapreduce:ListClusters",
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowEMRTemplateDiscovery"
        Effect   = "Allow"
        Action   = [
          "servicecatalog:SearchProducts",
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowSagemakerProjectManagement"
        Effect   = "Allow"
        Action   = [
          "sagemaker:CreateProject",
          "sagemaker:DeleteProject",
        ]
        Resource = "arn:aws:sagemaker:ca-central-1:*:project/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_emr_access_attachment" {
  role       = aws_iam_role.poc_role.name
  policy_arn = aws_iam_policy.sagemaker_emr_access.arn
}