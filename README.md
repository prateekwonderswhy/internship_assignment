# Pratilipi Assignment

Terraform script to automate instance creation with custom settings.

## Summary 

* Created a custom VPC and subnet with IGW and a route entry in the default route table to access the internet.

* Created an S3 bucket and assigned proper bucket policies.

* Created an IAM Role with Read/Write Access to the aforementioned S3 bucket

* Created a VPC endpoint for S3 access.

* Created a Security group with inbound(22, 8080), outbound(3306, 6379) ports open.

* Created an EC2 instance and attached the IAM role and Security Group to it.

* Configured remote backend using Amazon S3.

