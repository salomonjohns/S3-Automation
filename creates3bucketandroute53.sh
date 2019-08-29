#!/bin/bash
// Static Website on S3 Bucket with Route 53 for DNS - CLI Tutorial
DOMAIN_NAME=$1
REGION=$2
CREF=$(date +%Y-%m-%dT%H.%M.%S.%N)

echo -e $CREF
echo -e "www.$DOMAIN_NAME"

// Ensure we have a domain name
if [ -z "$DOMAIN_NAME" ]
then
        echo -e "\e[31mOops! You cannot leave the domain name empty... this isnt going to work \n"
        echo -e "\e[39m"
        exit 0
else
        echo -e "\e[32mGood... let us proceed! \n"
fi

// Ensure we have a region
if [[ $REGION != @(us-east-1|us-east-2|us-west-1|us-west-2|ap-south-1|ap-northeast-1|ap-northeast-2|ap-northeast-3|ap-southeast-1|ap-southeast-2|ca-central-1|cn-north-1|cn-northwest-1|eu-central-1|eu-west-1|eu-west-2|eu-west-3|eu-north-1|sa-east-1|me-south-1) ]]; then
        echo -e "\e[31mOops! The region is not valid... this isnt going to work \n"
        echo -e "\e[39m"
        exit 0
else
        echo -e "\e[32m Good... let us proceed! \n"
fi

// Assign Route53 HostedZoneId
if [[ $REGION == "us-east-1" ]]; then
		HZID="Z3AQBSTGFYJSTF"
elif [[ $REGION == "us-east-2" ]]; then
		HZID="Z2O1EMRO9K5GLX"
elif [[ $REGION == "us-west-1" ]]; then
		HZID="Z2F56UZL2M1ACD"
elif [[ $REGION == "us-west-2" ]]; then
		HZID="Z3BJ6K6RIION7M"
elif [[ $REGION == "ap-east-1" ]]; then
		HZID="ZNB98KWMFR0R6"
elif [[ $REGION == "ap-south-1" ]]; then
		HZID="Z11RGJOFQNVJUP"
elif [[ $REGION == "ap-northeast-3" ]]; then
		HZID="Z2YQB5RD63NC85"
elif [[ $REGION == "ap-northeast-2" ]]; then
		HZID="Z3W03O7B5YMIYP"
elif [[ $REGION == "ap-northeast-1" ]]; then
		HZID="Z3O0J2DXBE1FTB"
elif [[ $REGION == "ap-southeast-2" ]]; then
		HZID="Z1WCIGYICN2BYD"
elif [[ $REGION == "ap-southeast-1" ]]; then
		HZID="Z2M4EHUR26P7ZW"
elif [[ $REGION == "ca-central-1" ]]; then
		HZID="Z1QDHH18159H29"
elif [[ $REGION == "cn-northwest-1" ]]; then
		echo -e "\e[31mOops! The region is not supported\n"
		exit 0
elif [[ $REGION == "eu-central-1" ]]; then
		HZID="Z21DNDUVLTQW6Q"
elif [[ $REGION == "eu-west-1" ]]; then
		HZID="Z1BKCTXD74EZPE"
elif [[ $REGION == "eu-west-2" ]]; then
		HZID="Z3GKZC51ZF0DB4"
elif [[ $REGION == "eu-west-3" ]]; then
		HZID="Z3R1K369G5AVDG"
elif [[ $REGION == "eu-north-1" ]]; then
		HZID="Z3BAZG2TWCNX0D"
elif [[ $REGION == "sa-east-1" ]]; then
		HZID="Z7KQH4QJS55SO"
elif [[ $REGION == "me-south-1" ]]; then
		HZID="Z1MPMWCPA7YB62"
fi

// Create the bucket
aws s3api create-bucket --bucket $DOMAIN_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION
aws s3api create-bucket --bucket www.$DOMAIN_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION
echo -e "\e[32mBuckets Created\n"

// Set the Configuration Options
aws s3api put-public-access-block --bucket $DOMAIN_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
aws s3api put-public-access-block --bucket www.$DOMAIN_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
echo -e "\e[32mConfiguration Options Set\n"

// Configure for Static Website Hosting
// Idea for temp file from: https://stuff-things.net/2017/05/03/creating-an-s3-website-redirect-from-the-cli/
printf '{"IndexDocument": {"Suffix": "index.html"},"ErrorDocument": {"Key": "error.html"}}' $2 > website1.json
aws s3api put-bucket-website --bucket $DOMAIN_NAME --website-configuration file://website1.json

printf '{"RedirectAllRequestsTo": {"HostName": "string","Protocol": "http"}}' $2 > website2.json
aws s3api put-bucket-website --bucket www.$DOMAIN_NAME --website-configuration file://website2.json

// Cleanup
rm -rf website1.json
rm -rf website2.json
echo -e "\e[32mCleaned up website.json temp file\n"

// Configure Permissions
// Reference: https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-policy.html
printf '{"Version": "2012-10-17","Statement": [{"Sid": "PublicReadForGetBucketObjects","Effect": "Allow","Principal": "*","Action": ["s3:GetObject"],"Resource": ["arn:aws:s3:::'"$DOMAIN_NAME"'/*"]}]}' $2 > policy.json
printf '{"Version": "2012-10-17","Statement": [{"Sid": "PublicReadForGetBucketObjects","Effect": "Allow","Principal": "*","Action": ["s3:GetObject"],"Resource": ["arn:aws:s3:::'"www.$DOMAIN_NAME"'/*"]}]}' $2 > policy1.json
aws s3api put-bucket-policy --bucket $DOMAIN_NAME --policy file://policy.json
aws s3api put-bucket-policy --bucket www.$DOMAIN_NAME --policy file://policy1.json
echo -e "\e[32mPermissions Set\n"

// Cleanup
rm -rf policy.json
echo -e "\e[32mCleaned up policy.json temp file\n"

// Begin Route 53 Items
aws route53 create-hosted-zone --name $DOMAIN_NAME --hosted-zone-config Comment=string,PrivateZone=false --caller-reference "$CREF"
// Get ID of Zone
// Explanation - so we grep for the domain with a double quote ensuring we dont get subdomains by mistake we then replace double quotes and commas with nothing, we then set the delimiter to a forward slash and print out the collumn which is 3 in this case
ZONEID=$(aws route53 list-hosted-zones | grep -B 1 \"$DOMAIN_NAME | grep 'Id' | sed -e 's/,//g' -e 's/"//g' | awk -F '/' '{print $3}')

printf '{"Comment": "string","Changes": [{"Action": "CREATE","ResourceRecordSet": {"Name": "'"$DOMAIN_NAME"'","Type": "A","AliasTarget": {"HostedZoneId": '"$HZID"',"DNSName": "s3-website-'"$REGION"'.amazonaws.com.","EvaluateTargetHealth": false}}}]}' $2 > rec1.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://rec1.json

printf '{"Comment": "string","Changes": [{"Action": "CREATE","ResourceRecordSet": {"Name": "'"www.$DOMAIN_NAME"'","Type": "A","AliasTarget": {"HostedZoneId": '"$HZID"',"DNSName": "s3-website-'"$REGION"'.amazonaws.com.","EvaluateTargetHealth": false}}}]}' $2 > rec2.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://rec2.json

echo -e "\e[32mApplied record sets to DNS\n"

// Cleanup
rm -rf rec1.json
rm -rf rec2.json
echo -e "\e[32mCleaned up rec1.json and rec2.json temp file\n"
echo -e "\e[39m"
exit 0
