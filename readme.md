# AWS Serverless Infrastructure with Terraform

This repository contains the Terraform configuration files for deploying a serverless infrastructure on AWS. The infrastructure consists of a VPC, private subnets, RDS instances, API Gateway, and Lambda functions. All resources are created and managed using Terraform.

## Overview

The infrastructure is organized as follows:

- VPC with private subnets
- RDS instances with security groups
- API Gateway for managing access to Lambda functions
- Lambda functions with VPC access and IAM roles

## Getting Started

Follow these steps to deploy the infrastructure:

1. Ensure you have Terraform installed on your system. You can download Terraform [here](https://www.terraform.io/downloads.html).

2. Clone this repository and navigate to the project directory.

```
git clone https://github.com/FDR123/terraform-playground.git
cd terraform-playground
```

3. Navigate to the `lambdas/user_api` folder and make any necessary changes to the Lambda function.

4. In the `lambdas/user_api` folder, run the following command to bundle the Lambda function: ` npm run bundle`
5. Navigate to the `terraform` folder and initialize Terraform:
```
cd terraform
terraform init
```


6. Deploy the infrastructure by running the `terraform apply` command. This will prompt you to confirm the changes before proceeding: `terraform apply`


To destroy the infrastructure, run `terraform destroy`.

## Infrastructure Details

- **VPC**: The VPC is created with a CIDR block of `10.0.0.0/16`, with DNS support and hostnames enabled.
- **Subnets**: Two private subnets are created in the VPC, each in a different availability zone.
- **RDS**: A PostgreSQL RDS instance is created within the VPC, with a security group that allows inbound traffic from the Lambda security group.
- **API Gateway**: An API Gateway is created for each Lambda function, with a REST API that integrates with the Lambda function.
- **Lambda Functions**: Lambda functions are created with the necessary IAM roles and VPC access. The Lambda function's source code is deployed using Terraform.
