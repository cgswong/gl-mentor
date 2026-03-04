# Quick Start Guide

Get your ALB stack up and running in minutes!

## Prerequisites

1. AWS CLI installed and configured
2. Existing VPC with two public subnets in different AZs
3. Make utility installed (usually pre-installed on macOS/Linux)

## Step 1: Configure Parameters

Edit `parameters-example.json` with your VPC and subnet IDs:

```json
[
  {
    "ParameterKey": "VpcId",
    "ParameterValue": "vpc-YOUR_VPC_ID"
  },
  {
    "ParameterKey": "PublicSubnet1",
    "ParameterValue": "subnet-YOUR_SUBNET_1"
  },
  {
    "ParameterKey": "PublicSubnet2",
    "ParameterValue": "subnet-YOUR_SUBNET_2"
  },
  {
    "ParameterKey": "BackendType",
    "ParameterValue": "EC2AndLambda"
  },
  {
    "ParameterKey": "AllowedCidrBlock",
    "ParameterValue": "0.0.0.0/0"
  }
]
```

### Finding Your VPC and Subnets

```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# List public subnets in a VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-YOUR_VPC_ID" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

## Step 2: Validate Template

```bash
make validate lint
```

## Step 3: Deploy Stack

```bash
# Full deployment (validate, create, wait, test)
make deploy

# Or step by step
make create
make wait-create
make test
```

## Step 4: Access Your Application

```bash
# Get the ALB URL
make outputs

# Or directly test
make test
```

You should see output like:

```text
Stack Outputs: alb-demo
-----------------------------------------------------------------
|                          DescribeStacks                       |
+---------------------------+-----------------------------------+
|  LoadBalancerURL          |  http://alb-demo-alb-xxx.us-east-1.elb.amazonaws.com  |
|  EC2AccessPath            |  http://alb-demo-alb-xxx.us-east-1.elb.amazonaws.com/ec2  |
|  LambdaAccessPath         |  http://alb-demo-alb-xxx.us-east-1.elb.amazonaws.com/lambda  |
+---------------------------+-----------------------------------+
```

## Step 5: Test Endpoints

### Test All Endpoints

```bash
make test
```

### Test Individual Endpoints

```bash
# Test EC2 backend
make test-ec2

# Test Lambda backend
make test-lambda

# Test health check
make test-health
```

### Manual Testing

```bash
# Get the URL
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name alb-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text)

# Test default endpoint
curl $ALB_URL

# Test EC2 endpoint (EC2AndLambda mode)
curl $ALB_URL/ec2

# Test Lambda endpoint (EC2AndLambda mode)
curl $ALB_URL/lambda

# Test health check
curl $ALB_URL/health
```

## Common Operations

### Update Stack

```bash
# After modifying template or parameters
make update
make wait-update
make test
```

### Monitor Stack

```bash
# View stack status
make status

# View recent events
make events

# View Lambda logs
make logs
```

### Delete Stack

```bash
make delete
# Confirm with 'y'
make wait-delete
```

## Backend Type Options

### EC2 Only

```json
{
  "ParameterKey": "BackendType",
  "ParameterValue": "EC2Only"
}
```

- Access: `http://your-alb-url/`
- Single EC2 instance with Apache

### Lambda Only

```json
{
  "ParameterKey": "BackendType",
  "ParameterValue": "LambdaOnly"
}
```

- Access: `http://your-alb-url/`
- Single Lambda function (Python 3.13)

### Both (Default)

```json
{
  "ParameterKey": "BackendType",
  "ParameterValue": "EC2AndLambda"
}
```

- EC2: `http://your-alb-url/ec2`
- Lambda: `http://your-alb-url/lambda`
- Default: `http://your-alb-url/` → EC2

## Security Configuration

### Public Access (Default)

```json
{
  "ParameterKey": "AllowedCidrBlock",
  "ParameterValue": "0.0.0.0/0"
}
```

### Restrict to Your IP

```bash
# Get your public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)

# Update parameter
{
  "ParameterKey": "AllowedCidrBlock",
  "ParameterValue": "$MY_IP/32"
}
```

### Restrict to VPC

```json
{
  "ParameterKey": "AllowedCidrBlock",
  "ParameterValue": "10.0.0.0/8"
}
```

## Troubleshooting

### Stack Creation Failed

```bash
# View error events
make events

# Check specific resource status
aws cloudformation describe-stack-resources \
  --stack-name alb-demo \
  --query 'StackResources[?ResourceStatus==`CREATE_FAILED`]' \
  --output table
```

### Cannot Access ALB

1. Check security group allows your IP:

   ```bash
   make outputs | grep AllowedCidrBlock
   ```

2. Check target health:

   ```bash
   # Get target group ARN
   TG_ARN=$(aws cloudformation describe-stacks \
     --stack-name alb-demo \
     --query 'Stacks[0].Outputs[?OutputKey==`EC2TargetGroupArn`].OutputValue' \
     --output text)
   
   # Check health
   aws elbv2 describe-target-health --target-group-arn $TG_ARN
   ```

3. Check ALB is active:

   ```bash
   make status
   ```

### EC2 Instance Unhealthy

```bash
# Connect via Session Manager (no SSH key needed)
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name alb-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`EC2InstanceId`].OutputValue' \
  --output text)

aws ssm start-session --target $INSTANCE_ID

# Check Apache status
sudo systemctl status httpd

# Check health file
cat /var/www/html/health
```

### Lambda Not Responding

```bash
# View Lambda logs
make logs

# Test Lambda directly
FUNCTION_ARN=$(aws cloudformation describe-stacks \
  --stack-name alb-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' \
  --output text)

aws lambda invoke \
  --function-name $(echo $FUNCTION_ARN | awk -F: '{print $NF}') \
  --payload '{}' \
  response.json

cat response.json
```

## Advanced Usage

### Custom Stack Name

```bash
make create stack-name=prod-alb
make test stack-name=prod-alb
make delete stack-name=prod-alb
```

### Custom Parameter File

```bash
# Create prod-params.json
cp parameters-example.json prod-params.json
# Edit prod-params.json

# Deploy with custom parameters
make create parameter-file=prod-params.json stack-name=prod-alb
```

### Different Region

```bash
make create region=us-west-2 stack-name=west-alb
```

### Full Workflow Commands

```bash
# Complete deployment
make deploy

# Complete update
make redeploy

# Complete teardown
make teardown
```

## Next Steps

1. **Add HTTPS**: Request ACM certificate and update listener
2. **Add Auto Scaling**: Replace single EC2 with Auto Scaling Group
3. **Add Custom Domain**: Create Route 53 record pointing to ALB
4. **Add Monitoring**: Create CloudWatch dashboard for metrics
5. **Add CI/CD**: Integrate with CodePipeline for automated deployments

## Resources

- [CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## Support

For issues:

1. Check `make events` for error messages
2. Review CloudWatch Logs for Lambda errors
3. Use Session Manager to debug EC2 instances
4. Check target group health status
