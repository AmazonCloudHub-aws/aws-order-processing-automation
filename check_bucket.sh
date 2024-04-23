#!/bin/bash
bucket_name=$1

# Check the bucket's encryption settings
aws s3api get-bucket-encryption --bucket $bucket_name
