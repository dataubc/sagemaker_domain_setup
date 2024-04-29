# SageMaker_Terraform
A simple structure for creating a SageMaker Domain Using Terraform

Resources that will be created include:

- SageMaker Studio Domain, with a lifecycle script for auto-shutdown when idle
- A userprofile
- A VPC, subnset and security group
- Iam roles
- A Service Catalog Portfolio and Product including an EMR cloudformation tempalte that will be visible in SageMaker