#!/bin/bash
BUCKET_NAME=$1

if [ -z "$BUCKET_NAME" ]
then 
	echo -e "\e[31mOops! You cannot leave the bucket name empty... this isnt going to work \n"
	echo -e "\e[39m"
	exit 0
else
	echo -e "\e[32mGreen Good... you gave your bucket a name! \n"
fi

// Create the bucket
// Reference: https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
aws s3api create-bucket --bucket $BUCKET_NAME --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
echo -e "\e[32mBucket Created\n"

// Set the Configuration Options
// Reference: https://docs.aws.amazon.com/cli/latest/reference/s3api/put-public-access-block.html
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
echo -e "\e[32mConfiguration Options Set\n"

// Configure for Static Website Hosting
// Reference: https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-website.html
// Idea for temp file from: https://stuff-things.net/2017/05/03/creating-an-s3-website-redirect-from-the-cli/
printf '{"IndexDocument": {"Suffix": "index.html"},"ErrorDocument": {"Key": "error.html"}}' $2 > website.json
aws s3api put-bucket-website --bucket $BUCKET_NAME --website-configuration file://website.json
echo -e "\e[32mStatic Hosting Options Set\n"
// Cleanup 
rm -rf website.json
echo -e "\e[32mCleaned up website.json temp file\n"

// Configure Permissions
// Reference: https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-policy.html
printf '{"Version": "2012-10-17","Statement": [{"Sid": "PublicReadForGetBucketObjects","Effect": "Allow","Principal": "*","Action": ["s3:GetObject"],"Resource": ["arn:aws:s3:::'"$BUCKET_NAME"'/*"]}]}' $2 > policy.json
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://policy.json
echo -e "\e[32mPermissions Set\n"
rm -rf policy.json
echo -e "\e[32mCleaned up policy.json temp file\n"
echo -e "\e[32mProceed to upload a file and test access!\n\n"
echo -e "\e[39m"
