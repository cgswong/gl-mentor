#!/usr/bin/env bash
# DESC: Use AWS CLI to create simple VPC.

unset AWS_CLI_AUTO_PROMPT
export VPC_CIDR=${1:-"10.50.0.0/16"}
export VPC_PUBLIC_SUBNET_CIDR_1=${1:-"10.50.0.0/24"}
export VPC_PUBLIC_SUBNET_CIDR_2=${1:-"10.50.2.0/24"}
export VPC_PUBLIC_SUBNET_CIDR_1=${1:-"10.50.1.0/24"}
export VPC_PUBLIC_SUBNET_CIDR_2=${1:-"10.50.3.0/24"}
export AWS_REGION=us-east-1
export AWS_PAGER=
export AWS_PROFILE=default

echo "Create VPC and add tags"
aws ec2 create-vpc \
  --cidr-block ${VPC_CIDR} \
  --tag-specifications ResourceType=vpc,Tags='[{Key="Name",Value="demo-cli-vpc"}]'
VPC_ID=$(aws ec2 describe-vpcs --filters Name=cidr,Values=\["${VPC_CIDR}"\] --query 'Vpcs[*].VpcId' --output=text)

echo "Create subnets (for public and private)"
aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block ${VPC_PUBLIC_SUBNET_CIDR_1} \
  --availability-zone us-east-1a \
  --tag-specifications ResourceType=subnet,Tags='[{Key="Name",Value="demo-cli-pub-us-east-1a"}]'
PUB_SUBNET_1_ID=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock==\`${VPC_PUBLIC_SUBNET_CIDR_1}\`].SubnetId" --output=text)
aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block ${VPC_PUBLIC_SUBNET_CIDR_2} \
  --availability-zone us-east-1b \
  --tag-specifications ResourceType=subnet,Tags='[{Key="Name",Value="demo-cli-pub-us-east-1b"}]'
PUB_SUBNET_2_ID=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock==\`${VPC_PUBLIC_SUBNET_CIDR_2}\`].SubnetId" --output=text)
aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block ${VPC_PRIVATE_SUBNET_CIDR_1} \
  --availability-zone us-east-1a \
  --tag-specifications ResourceType=subnet,Tags='[{Key="Name",Value="demo-cli-prv-us-east-1a"}]'
PRV_SUBNET_1_ID=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock==\`${VPC_PRIVATE_SUBNET_CIDR_1}\`].SubnetId" --output=text)
aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block ${VPC_PRIVATE_SUBNET_CIDR_2} \
  --availability-zone us-east-1a \
  --tag-specifications ResourceType=subnet,Tags='[{Key="Name",Value="demo-cli-prv-us-east-1b"}]'
PRV_SUBNET_2_ID=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock==\`${VPC_PRIVATE_SUBNET_CIDR_2}\`].SubnetId" --output=text)

echo "Create IGW and attach to VPC"
aws ec2 create-internet-gateway \
  --tag-specifications ResourceType=internet-gateway,Tags='[{Key="Name",Value="demo-cli-igw"}]'
IGW_ID=$(aws ec2 describe-internet-gateways --query 'InternetGateways[?(Attachments==`[]` && Tags[?Value==`demo-cli-igw`])].InternetGatewayId' --output text)
aws ec2 attach-internet-gateway \
  --internet-gateway-id ${IGW_ID} \
  --vpc-id ${VPC_ID}

echo "Create NAT GW with EIP"
aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications ResourceType=elastic-ip,Tags='[{Key="Name",Value="demo-cli-eip"}]'
EIP_ALLOC_ID=$(aws ec2 describe-addresses --query 'Addresses[?Tags[?Value==`demo-cli-eip`]].AllocationId' --output text)
aws ec2 create-nat-gateway \
  --subnet-id ${PUB_SUBNET_1_ID} \
  --allocation-id ${EIP_ALLOC_ID} \
  --tag-specifications ResourceType=natgateway,Tags='[{Key="Name",Value="demo-cli-natgw-us-east-1"}]'
NATGW_ID=$(aws ec2 describe-nat-gateways --query "NatGateways[?VpcId==\`${VPC_ID}\`].NatGatewayId" --output=text)

echo "Create Route Tables (public and private)"
aws ec2 create-route-table \
  --vpc-id ${VPC_ID} \
  --tag-specifications ResourceType=route-table,Tags='[{Key="Name",Value="demo-cli-pub-rt"}]'
PUB_RT_ID=$(aws ec2 describe-route-tables --query 'RouteTables[?Tags[?Value==`demo-cli-pub-rt`]].RouteTableId' --output=text)

aws ec2 create-route-table \
  --vpc-id ${VPC_ID} \
  --tag-specifications ResourceType=route-table,Tags='[{Key="Name",Value="demo-cli-prv-rt"}]'
PRV_RT_ID=$(aws ec2 describe-route-tables --query 'RouteTables[?Tags[?Value==`demo-cli-prv-rt`]].RouteTableId' --output=text)

echo "Create routes and associations in RT"
aws ec2 create-route \
  --route-table-id ${PUB_RT_ID} \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id ${IGW_ID}
aws ec2 create-route \
  --route-table-id ${PRV_RT_ID} \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id ${NATGW_ID}

aws ec2 associate-route-table \
  --route-table-id ${PUB_RT_ID} \
  --subnet-id ${PUB_SUBNET_1_ID}
aws ec2 associate-route-table \
  --route-table-id ${PUB_RT_ID} \
  --subnet-id ${PUB_SUBNET_2_ID}

aws ec2 associate-route-table \
  --route-table-id ${PRV_RT_ID} \
  --subnet-id ${PRV_SUBNET_1_ID}
aws ec2 associate-route-table \
  --route-table-id ${PRV_RT_ID} \
  --subnet-id ${PRV_SUBNET_2_ID}

echo "Create security group (SG) with rules for VPC resources"
aws ec2 create-security-group \
  --description "Allow lab access" \
  --group-name demo-cli-sg \
  --vpc-id ${VPC_ID} \
  --tag-specifications ResourceType=security-group,Tags='[{Key="Name",Value="demo-cli-sg"}]'
SG_ID=$(aws ec2 describe-security-groups --query 'SecurityGroups[?Tags[?Value==`demo-cli-sg`]].GroupId' --output text)
aws ec2 authorize-security-group-ingress \
  --group-id ${SG_ID} \
  --protocol tcp \
  --port 22 \
  --cidr $(curl https://checkip.amazonaws.com)/32 \
  --tag-specifications ResourceType=security-group-rule,Tags='[{Key="Name",Value="demo-cli-in-tcp22-sgr"}]'
aws ec2 authorize-security-group-ingress \
  --group-id ${SG_ID} \
  --protocol tcp \
  --port 80 \
  --cidr $(curl https://checkip.amazonaws.com)/32 \
  --tag-specifications ResourceType=security-group-rule,Tags='[{Key="Name",Value="demo-cli-in-tcp80-sgr"}]'
