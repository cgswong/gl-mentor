# Quick Start Guide

Get your auto-scaling web application running in under 5 minutes.

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Valid email address for notifications

## 5-Minute Deployment

### Step 1: Update Parameters (30 seconds)

Edit `parameters.json` and replace the email address:

```json
[
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "t4g.micro"
  },
  {
    "ParameterKey": "InstanceArchitecture",
    "ParameterValue": "arm64"
  },
  {
    "ParameterKey": "MinSize",
    "ParameterValue": "1"
  },
  {
    "ParameterKey": "MaxSize",
    "ParameterValue": "3"
  },
  {
    "ParameterKey": "DesiredCapacity",
    "ParameterValue": "2"
  },
  {
    "ParameterKey": "OperatorEmail",
    "ParameterValue": "YOUR-EMAIL@example.com"  ← Change this!
  }
]
```

### Step 2: Deploy (10 seconds)

```bash
make deploy
```

### Step 3: Wait for Completion (3-5 minutes)

```bash
make wait-complete
```

You'll see:
```
✓ Stack operation completed
```

### Step 4: Get Your URL (5 seconds)

```bash
make get-url
```

Output:
```
http://autoscaling-demo-alb-1234567890.us-east-1.elb.amazonaws.com
```

### Step 5: Open in Browser (5 seconds)

```bash
make open-url
```

Or manually visit the URL from step 4.

## What You Just Created

- ✅ Multi-AZ VPC with public and private subnets
- ✅ Application Load Balancer (internet-facing)
- ✅ Auto Scaling Group with 2 EC2 instances
- ✅ CloudWatch alarms for automatic scaling
- ✅ SNS email notifications
- ✅ Session Manager access (no SSH keys!)

## Next Steps

### Confirm Email Subscription

Check your email and confirm the SNS subscription to receive scaling notifications.

### Access an Instance

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=autoscaling-demo-asg" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

# Connect to an instance
aws ssm start-session --target i-1234567890abcdef0
```

### Test Auto Scaling

Generate CPU load to trigger scaling:

```bash
# Connect to instance first
aws ssm start-session --target <instance-id>

# Generate load (in the session)
yes > /dev/null &
yes > /dev/null &

# Watch scaling events (in another terminal)
make events
```

### Monitor Your Stack

```bash
# Stack status
make status

# Recent events
make events

# All outputs
make outputs

# All resources
make resources
```

## Common Customizations

### Change Instance Type

Edit `parameters.json`:
```json
{
  "ParameterKey": "InstanceType",
  "ParameterValue": "t4g.small"  ← Larger instance
}
```

Then update:
```bash
make update
```

### Change Capacity

Edit `parameters.json`:
```json
{
  "ParameterKey": "MinSize",
  "ParameterValue": "2"
},
{
  "ParameterKey": "MaxSize",
  "ParameterValue": "5"
},
{
  "ParameterKey": "DesiredCapacity",
  "ParameterValue": "3"
}
```

Then update:
```bash
make update
```

### Use x86_64 Instead of ARM64

Edit `parameters.json`:
```json
{
  "ParameterKey": "InstanceType",
  "ParameterValue": "t3.micro"  ← x86_64 instance
},
{
  "ParameterKey": "InstanceArchitecture",
  "ParameterValue": "x86_64"  ← Change architecture
}
```

Then update:
```bash
make update
```

## Cleanup

When you're done testing:

```bash
make delete
```

Confirm deletion when prompted, then wait:

```bash
make wait-delete
```

## Troubleshooting

### Stack Creation Failed

Check events:
```bash
make events
```

Common issues:
- Invalid email format
- Insufficient IAM permissions
- Service limits exceeded

### Can't Access Application

1. Wait for instances to be healthy:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn $(aws cloudformation describe-stacks \
       --stack-name autoscaling-demo \
       --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupARN`].OutputValue' \
       --output text)
   ```

2. Check security groups:
   ```bash
   make resources
   ```

### Email Not Received

Check spam folder or confirm subscription manually:
```bash
# Get SNS topic ARN
make outputs | grep NotificationTopicARN

# Subscribe manually
aws sns subscribe \
  --topic-arn <topic-arn> \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## Cost Estimate

Running this stack 24/7 in us-east-1:

| Resource | Monthly Cost |
|----------|--------------|
| 2x t4g.micro | ~$12 |
| Application Load Balancer | ~$16 |
| Regional NAT Gateway | ~$32 |
| Data transfer | ~$10 |
| **Total** | **~$70** |

**Cost Saving Tips**:
- Use t4g.nano for minimal testing (~$6/month for instances)
- Delete when not in use
- Regional NAT Gateway provides automatic multi-AZ redundancy at lower cost

## Getting Help

- Full documentation: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Makefile commands: `make help`

## What's Next?

1. **Add HTTPS**: Request ACM certificate and add HTTPS listener
2. **Custom Domain**: Point your domain to the ALB
3. **Deploy Your App**: Modify the user data to deploy your application
4. **Enable Logging**: Add ALB access logs and CloudWatch Logs
5. **Add Monitoring**: Create CloudWatch Dashboard

See the [README.md](README.md) for detailed instructions.

---

**Congratulations!** 🎉 You now have a production-ready auto-scaling web application running on AWS.
