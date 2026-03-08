# Production-Ready VPC CloudFormation Template

## Overview
This CloudFormation template creates a production-ready VPC with configurable features including IPAM support, optional NAT Gateway, VPC Flow Logs, and auto-calculated subnet CIDRs.

## Features

- **Flexible CIDR Allocation**: User-specified CIDR or IPAM-allocated CIDR
- **Additional CIDRs**: Support for up to 4 additional CIDR blocks
- **Auto-Calculated Subnets**: 2-3 public and private subnets with automatic CIDR calculation
- **AZ-ID Based Placement**: Subnets placed using Availability Zone IDs for consistency
- **Gateway Endpoints**: Mandatory S3 and DynamoDB VPC endpoints
- **Optional NAT Gateway**: Regional (not zonal) NAT Gateway with reusable EIP
- **Optional VPC Flow Logs**: CloudWatch or S3 destinations
- **Comprehensive Tagging**: Resources tagged with Name, Type, Region, and AZ-ID

## Parameters

### Network Configuration
- `VPCCidr`: CIDR block for VPC (default: 10.0.0.0/16)
- `IPAMPoolId`: Optional IPAM Pool ID (supersedes VPCCidr)
- `IPAMNetmaskLength`: Netmask length for IPAM allocation (default: 16)
- `AdditionalCidr1-4`: Up to 4 additional CIDR blocks

### Subnet Configuration
- `NumberOfAZs`: Number of AZs (2 or 3, default: 2)
- `PublicSubnetBits`: Subnet size bits for public subnets (default: 8 = /24)
- `PrivateSubnetBits`: Subnet size bits for private subnets (default: 8 = /24)
- `AvailabilityZoneId1-3`: AZ IDs for subnet placement (e.g., use1-az1)

### Optional Features
- `EnableNATGateway`: Enable NAT Gateway (no/yes, default: no)
- `EnableVPCFlowLog`: Enable VPC Flow Logs (no/cloudwatch/s3, default: no)
- `FlowLogS3BucketArn`: S3 bucket ARN for Flow Logs (if s3 enabled)
- `FlowLogRetentionDays`: CloudWatch retention days (default: 7)

## Outputs

- `VPCId`: VPC ID
- `VPCCidrBlock`: VPC CIDR block
- `PublicSubnet1-3Id`: Individual public subnet IDs
- `PrivateSubnet1-3Id`: Individual private subnet IDs
- `PublicSubnetIds`: Comma-separated list of public subnet IDs
- `PrivateSubnetIds`: Comma-separated list of private subnet IDs
- `DefaultSecurityGroupId`: Default security group ID
- `NATGatewayId`: NAT Gateway ID (if enabled)

## Usage Examples

### Basic 2-AZ VPC
```bash
aws cloudformation create-stack \
  --stack-name my-vpc \
  --template-body file://template.cfn.yaml \
  --parameters \
    ParameterKey=VPCCidr,ParameterValue=10.0.0.0/16 \
    ParameterKey=NumberOfAZs,ParameterValue=2 \
    ParameterKey=AvailabilityZoneId1,ParameterValue=use1-az1 \
    ParameterKey=AvailabilityZoneId2,ParameterValue=use1-az2
```

### VPC with NAT Gateway and CloudWatch Flow Logs
```bash
aws cloudformation create-stack \
  --stack-name my-vpc-nat \
  --template-body file://template.cfn.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=VPCCidr,ParameterValue=10.0.0.0/16 \
    ParameterKey=NumberOfAZs,ParameterValue=2 \
    ParameterKey=AvailabilityZoneId1,ParameterValue=use1-az1 \
    ParameterKey=AvailabilityZoneId2,ParameterValue=use1-az2 \
    ParameterKey=EnableNATGateway,ParameterValue=yes \
    ParameterKey=EnableVPCFlowLog,ParameterValue=cloudwatch \
    ParameterKey=FlowLogRetentionDays,ParameterValue=30
```

### IPAM-Allocated VPC with 3 AZs
```bash
aws cloudformation create-stack \
  --stack-name my-vpc-ipam \
  --template-body file://template.cfn.yaml \
  --parameters \
    ParameterKey=IPAMPoolId,ParameterValue=ipam-pool-0123456789abcdef \
    ParameterKey=IPAMNetmaskLength,ParameterValue=16 \
    ParameterKey=NumberOfAZs,ParameterValue=3 \
    ParameterKey=AvailabilityZoneId1,ParameterValue=use1-az1 \
    ParameterKey=AvailabilityZoneId2,ParameterValue=use1-az2 \
    ParameterKey=AvailabilityZoneId3,ParameterValue=use1-az4
```

### Using Parameter File
```bash
aws cloudformation create-stack \
  --stack-name my-vpc \
  --template-body file://template.cfn.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM
```

## Validation

### Lint Check
```bash
cfn-lint template.cfn.yaml
```

### Validate Template
```bash
aws cloudformation validate-template \
  --template-body file://template.cfn.yaml
```

## Notes

- **AZ IDs**: Use AZ IDs (e.g., use1-az1) instead of AZ names for consistent placement across accounts
- **NAT Gateway**: Single regional NAT Gateway in first public subnet for cost optimization
- **Flow Logs**: Requires CAPABILITY_IAM when enabling CloudWatch Flow Logs
- **Subnet Sizing**: SubnetBits of 8 creates /24 subnets in a /16 VPC (256 IPs per subnet)
- **IPAM**: When IPAMPoolId is provided, it supersedes VPCCidr parameter
- **Gateway Endpoints**: S3 and DynamoDB endpoints are always created (no additional cost)

## Cost Considerations

- **NAT Gateway**: ~$32/month + data processing charges
- **VPC Flow Logs (CloudWatch)**: Storage and ingestion costs based on traffic volume
- **VPC Flow Logs (S3)**: S3 storage costs only
- **Gateway Endpoints**: No additional charge
