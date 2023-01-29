#!/usr/bin/env bash
# DESC: Use AWS CLI to create simple EC2.

unset AWS_CLI_AUTO_PROMPT
export AWS_REGION=us-east-1
export AWS_PAGER=
export AWS_PROFILE=gl-mentor
export PUB_SUBNET_ID=$1
export SG_ID=$2

echo "Create SSH key pair (Session Manager preferred)"
aws ec2 create-key-pair \
  --key-name demo-cli-us-east-1-kp \
  --query 'KeyMaterial' \
  --tag-specifications ResourceType=key-pair,Tags='[{Key="Name",Value="demo-cli-us-east-1-kp"}]' \
  --output text >~/.ssh/demo-cli-us-east-1-kp.pem
chmod 400 ~/.ssh/demo-cli-us-east-1-kp.pem

echo "Launch EC2"
aws ec2 run-instances \
  --image-id ami-033b95fb8079dc481 \
  --count 1 \
  --instance-type t2.micro \
  --key-name demo-cli-us-east-1-kp \
  --subnet-id ${PUB_SUBNET_ID} \
  --security-group-ids ${SG_ID} \
  --associate-public-ip-address \
  --key-name demo-cli-us-east-1-kp \
  --tag-specifications ResourceType=instance,Tags='[{Key="Name",Value="demo-cli-ec2"}]'
INSTANCE_ID=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Value==`demo-cli-ec2`]].InstanceId' --output=text)
