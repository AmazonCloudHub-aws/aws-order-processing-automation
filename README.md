# AWS S3 Lambda DynamoDB Terraform

This repository contains Terraform configurations for provisioning essential AWS infrastructure components, such as S3 buckets, Lambda functions, and DynamoDB tables. 

## Overview

The provided Terraform configuration automates the setup and configuration of a serverless architecture. It facilitates seamless integration between S3 event triggers and DynamoDB data storage.

## Components

- **S3 Buckets**: Sets up S3 buckets to store and manage data.
- **Lambda Functions**: Defines Lambda functions for processing events triggered by S3 actions.
- **DynamoDB Tables**: Creates DynamoDB tables for storing and managing structured data.

## Purpose

The primary goal of this repository is to streamline the deployment and management of AWS serverless infrastructure. By using Terraform, users can easily provision the necessary resources while ensuring consistency and repeatability across deployments.

## Usage

1. **Clone Repository**: Clone this repository to your local machine.
2. **Configure Terraform**: Customize the Terraform configurations according to your requirements.
3. **Initialize Terraform**: Run `terraform init` to initialize Terraform and download necessary providers.
4. **Plan Deployment**: Execute `terraform plan` to preview the changes Terraform will make to your infrastructure.
5. **Apply Changes**: Apply the changes by running `terraform apply`. Review and confirm the changes to deploy the infrastructure.
6. **Manage Infrastructure**: Use Terraform to manage and update the infrastructure as needed.

## Architecture Diagram

Below is the architecture diagram showing the interaction between S3, Lambda, and DynamoDB with the necessary IAM roles:

![Architecture Diagram](/Users/damilolaijato/Desktop/github/aws.png)
