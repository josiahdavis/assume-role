# To make this file executable, run:
# chmod +x assume-role.sh
usage() {
    echo " "
    echo "  Usage:"; echo "    $0 USER new-account role MFA_TOKEN";
    echo "  e.g.,"; echo "   $0 davjosia 123456789012 Developer 123456";
    exit 1;
}

# Make sure that the USER adds the mfa code
if [ "$#" -ne 4 ]; then
    usage
fi

# Set the arguments
# To give these default values simply replace $# with ${#:default-value}
USER=$1             # e.g., davjosia
NEW_ACCOUNT=$2      # e.g., 123456789012
ROLE=$3             # e.g., Developer
MFA_TOKEN=$4        # e.g., 123456

# Retrieve account number
old_account=$(aws sts get-caller-identity --query Account --output text)

# Retrieve the credentials
result=$(aws sts assume-role \
--role-arn arn:aws:iam::${NEW_ACCOUNT}:role/${ROLE} \
--role-session-name ${ROLE} \
--serial-number arn:aws:iam::${old_account}:mfa/${USER} \
--token-code ${MFA_TOKEN} | jq '.Credentials')

# Extract the individual credentials
a=$(echo ${result} | jq '.AccessKeyId' | tr -d \")
b=$(echo ${result} | jq '.SecretAccessKey' | tr -d \")
c=$(echo ${result} | jq '.SessionToken' | tr -d \")

# Update the local credential file
aws configure set profile.${ROLE}.aws_access_key_id $a
aws configure set profile.${ROLE}.aws_secret_access_key $b
aws configure set profile.${ROLE}.aws_session_token $c

# Simple test to make sure the role is working
aws s3 ls --profile ${ROLE}
