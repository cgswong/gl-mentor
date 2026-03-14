# EC2 Instance CloudFormation Template

A modern, production-ready CloudFormation template for deploying Amazon EC2 instances with optimal pricing, security, and operational efficiency.

## Overview

This template automates the deployment of an EC2 instance with the following features:

- **Amazon Linux 2023**: Modern, lightweight operating system with long-term support
- **Session Manager Access**: Secure shell access without SSH keys or security group management
- **Cost-Optimized Instance Types**: t3/t4g (burstable) and m5/m7g (balanced) families
- **ARM64 Support**: Graviton processors for better price/performance
- **IAM Role Management**: Managed instance permissions for AWS service access
- **CloudWatch Integration**: Built-in monitoring capabilities
- **Auto-Healing**: CreationPolicy ensures instance health before stack completion
- **Web Server Demo**: Apache HTTP server for demonstration purposes

## Prerequisites

### AWS Account Requirements

- An AWS account with appropriate IAM permissions to:
  - Create/manage EC2 instances
  - Create/manage IAM roles and instance profiles
  - Create/manage security groups (optional, default VPC)
  - Use AWS Systems Manager Session Manager

### Local Requirements

- AWS CLI v2 configured with credentials
- Bash shell (Linux/macOS) or PowerShell (Windows)
- (Optional) jq for JSON parsing

### Minimum AWS Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackResources",
        "ec2:*",
        "iam:CreateRole",
        "iam:CreateInstanceProfile",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "ssm:StartSession"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Deploy the Stack (Default Configuration)

```bash
# Deploy with default parameters (t3.small, x86_64, no SSH)
make deploy

# Or use AWS CLI directly
aws cloudformation create-stack \
  --stack-name my-ec2-instance \
  --template-body file://template.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

### 2. Connect to the Instance

```bash
# Get the Instance ID from stack outputs
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
  --output text)

# Connect using Session Manager (recommended)
aws ssm start-session --target $INSTANCE_ID
```

### 3. Access the Web Server

```bash
# Get the public DNS from stack outputs
PUBLIC_DNS=$(aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicDNS`].OutputValue' \
  --output text)

# Open in browser or curl
curl http://$PUBLIC_DNS
```

### 4. Clean Up Resources

```bash
make cleanup
# Or: aws cloudformation delete-stack --stack-name my-ec2-instance
```

## Parameters

### InstanceType

**Type**: String
**Default**: `t4g.micro`
**Description**: EC2 instance type

**Available Options**:

| Instance Type | Family | Architecture | Best For | Est. Monthly Cost |
|---|---|---|---|---|
| t3.nano, t3.micro | Burstable (x86) | Intel/AMD | Dev, testing | $3-6 |
| t3.small, t3.medium | Burstable (x86) | Intel/AMD | Light workloads | $8-16 |
| t4g.nano, t4g.micro | Burstable (ARM) | Graviton2 | Cost-optimized dev | $3-5 |
| t4g.small, t4g.medium | Burstable (ARM) | Graviton2 | Cost-optimized light | $6-12 |
| m5.large, m5.xlarge | General (x86) | Intel/AMD | Sustained workloads | $70-140 |
| m7g.large, m7g.xlarge | General (ARM) | Graviton3 | Cost-optimized sustained | $50-100 |
| c5.large, c5.xlarge | Compute (x86) | Intel/AMD | CPU-intensive | $85-170 |
| c7g.large, c7g.xlarge | Compute (ARM) | Graviton3 | Cost-optimized compute | $65-130 |

**Recommendation**: Start with `t3.small` (x86_64) for general testing or `t4g.small` (ARM64) for cost optimization.

### Architecture

Architecture is determined from the selected `InstanceType`. ARM64 instance types (for
example `t4g.*`, `m6g.*`) will use an ARM64 AL2023 AMI; x86 instance types will use the
x86 AL2023 AMI. You do not need to provide an explicit architecture parameter.

### KeyName

**Type**: String
**Default**: (empty - optional)
**Description**: Existing EC2 key pair name for SSH access (optional, leave empty if not needed)

### EnableSSH

**Type**: String
**Default**: `false`
**Description**: Enable SSH access on port 22 (`true` or `false`)

**Options**:
- `true`: Opens port 22 to the `SSHLocation` CIDR (requires `KeyName` parameter)
- `false`: SSH disabled (Session Manager recommended)

**Security Recommendation**: Use Session Manager instead of SSH for better security auditing and credential management.

## Template Structure

### IAM Resources

- **EC2InstanceRole**: IAM role with permissions for:
  - Session Manager access (AmazonSSMManagedInstanceCore)
  - CloudWatch monitoring (CloudWatchAgentServerPolicy)
- **EC2InstanceProfile**: Binds role to EC2 instance

### Security Resources

- **InstanceSecurityGroup**: Manages inbound/outbound traffic
  - HTTP (port 80) - always allowed
  - SSH (port 22) - only if EnableSSHAccess=Yes
  - All outbound traffic allowed

### Compute Resources

- **EC2Instance**: Main instance with:
  - AL2023 AMI (retrieved dynamically via SSM Parameter Store)
  - Auto-scaling friendly tags
  - CloudFormation helper integration (cfn-init, cfn-signal)
  - User data for automatic setup
  - CreationPolicy to monitor initialization

### Supporting Components

- **Metadata**: CloudFormation console parameter grouping for better UX
- **Mappings**: Instance type documentation
- **Conditions**: Conditional SSH access and parameter handling

## Outputs

The stack creates the following outputs for convenient reference:

| Output | Description | Use Case |
|---|---|---|
| InstanceId | EC2 instance ID | Session Manager connections |
| InstanceAZ | Availability Zone | Multi-AZ considerations |
| PrivateIP | Internal IP address | VPC communication |
| PublicIP | Public IP address | External access (if applicable) |
| PublicDNS | DNS name | Web server access |
| SecurityGroupId | Security group ID | Additional rule management |
| IAMRoleArn | Role ARN | Permission elevation, cross-stack references |
| SessionManagerCommand | Ready-to-use connection command | Quick terminal access |
| WebServerURL | HTTP endpoint | Web application access |
| StackName | Stack name | Reference and tracking |

## Usage Examples

### Example 1: Cost-Optimized ARM64 Instance

```bash
# Using t4g.small (Graviton2, ~$10/month vs t3.small at ~$8/month, YMMV)
make deploy \
  STACK_NAME=cost-optimized-demo \
  INSTANCE_TYPE=t4g.small \
  ARCHITECTURE=arm64
```

### Example 2: General Purpose with SSH Access

```bash
  # For teams requiring SSH access
  make deploy \
    STACK_NAME=ssh-enabled \
    KEY_NAME=my-ec2-keypair \
    ENABLE_SSH=true
```

### Example 3: High-Performance Workload

```bash
# For CPU-intensive applications
make deploy \
  STACK_NAME=compute-intensive \
  INSTANCE_TYPE=c7g.xlarge \
  ARCHITECTURE=arm64
```

### Example 4: Balanced Sustained Load

```bash
# For servers needing consistent resources
make deploy \
  STACK_NAME=production-server \
  INSTANCE_TYPE=m5.xlarge \
  ARCHITECTURE=x86_64
```

## Management Operations

### View Stack Status

```bash
# List all stacks
aws cloudformation list-stacks

# Describe specific stack
aws cloudformation describe-stacks --stack-name my-ec2-instance
```

### Update Stack

```bash
# Modify parameters (e.g., instance type requires replacement)
aws cloudformation update-stack \
  --stack-name my-ec2-instance \
  --template-body file://template.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t3.medium
```

### Monitor Events

```bash
# Watch stack creation/update progress
watch -n 5 'aws cloudformation describe-stack-events \
  --stack-name my-ec2-instance \
  --query "StackEvents[0:10]" \
  --output table'
```

### Retrieve Outputs

```bash
# Get all outputs
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs' \
  --output table

# Get specific output
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs[?OutputKey==`SessionManagerCommand`].OutputValue' \
  --output text
```

### Connect to Instance

```bash
# Session Manager (no SSH key required)
aws ssm start-session --target i-1234567890abcdef0

# Or use the connection helper
STACK_NAME=my-ec2-instance
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
  --output text)
aws ssm start-session --target $INSTANCE_ID

# SSH (if enabled and key available)
INSTANCE_IP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
  --output text)
ssh -i /path/to/key.pem ec2-user@$INSTANCE_IP
```

## Instance Configuration

### User Data Execution

During instance initialization, the template:

1. Updates all system packages via dnf
2. Installs CloudFormation bootstrap scripts
3. Executes cfn-init to configure packages, services, and files
4. Sends completion signal with cfn-signal
5. Ensures Systems Manager Agent is running

### Pre-Installed Services

- **httpd (Apache)**: HTTP web server on port 80
- **amazon-ssm-agent**: Systems Manager agent for Session Manager access

### Custom HTML Files

- `/var/www/html/index.html`: Demo page with stack information
- `/var/www/html/health.html`: Health check endpoint returning "ok"

### Extending Configuration

To add additional packages or configuration:

1. Modify the `Metadata.AWS::CloudFormation::Init.config.packages` section to add dnf packages
2. Add service definitions in the `services` section
3. Add file configurations in the `files` section
4. Update stack: `make update`

Example additions to template:

```yaml
packages:
  dnf:
    nodejs: []
    git: []
    htop: []
services:
  enabled:
    nodejs-service: true
files:
  /etc/environment:
    content: |
      NODE_ENV=production
      LOG_LEVEL=info
```

## Troubleshooting

### Stack Creation Failed

```bash
# View detailed error messages
aws cloudformation describe-stack-events \
  --stack-name my-ec2-instance \
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED']" \
  --output table

# Check CloudFormation logs (if initialization failed)
# Connect to instance and check: /var/log/cloud-init-output.log
```

### Cannot Connect via Session Manager

**Cause**: SSM Agent not running or role permissions insufficient

```bash
# Verify role has correct policy
aws iam list-attached-role-policies --role-name my-ec2-instance-role

# Check EC2 instance systems manager status
aws ssm describe-instance-information --instance-information-filter-list \
  "key=InstanceIds,valueSet=i-1234567890abcdef0"

# View SSM Agent logs on instance
tail -f /var/log/amazon/ssm/amazon-ssm-agent.log
```

### Web Server Not Responding

```bash
# Connect via Session Manager
aws ssm start-session --target i-xxxxx

# Check httpd status
sudo systemctl status httpd

# Verify listening ports
sudo netstat -tlnp | grep httpd

# Restart service
sudo systemctl restart httpd
```

### SSH Connection Refused

**Note**: SSH is disabled by default. To enable:

1. Re-deploy stack with `EnableSSHAccess=Yes` and `KeyName=your-key-pair`
2. Wait for stack update completion
3. Use SSH: `ssh -i key.pem ec2-user@<public-ip>`

### Insufficient IAM Permissions

Error: "User: arn:aws:iam::123456789:user/test is not authorized to perform..."

**Resolution**:
- Ensure IAM user has CloudFormation, EC2, and IAM permissions
- See "Minimum AWS Permissions" section in Prerequisites

## Best Practices

### 1. Use Instance Types Matching the Architecture

```yaml
# ✅ CORRECT
InstanceType: t4g.small
ArchitecturePreference: arm64

# ❌ WRONG - t3 is x86_64 only
InstanceType: t3.small
ArchitecturePreference: arm64
```

### 2. Leverage Session Manager for Security

- **Advantage**: No SSH key management needed
- **Advantage**: Full AWS audit logging (CloudTrail)
- **Advantage**: No security group ports needed
- **Implementation**: Default template configuration

### 3. Tag Resources for Cost Tracking

The template automatically tags resources with:
- `Name`: Stack name prefix
- `ManagedBy`: CloudFormation
- `StackName`: Full stack name

Add additional tags in the stack parameters when deploying.

### 4. Monitor Instance Health

```bash
# Check SSM automation documents
aws ssm list-documents --document-filter-list "key=DocumentType,value=Automation"

# Retrieve instance metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average
```

### 5. Implement Automatic Backups

Combine with AWS Backup for automated EBS snapshots:

```bash
# Create backup vault
aws backup create-backup-vault --backup-vault-name my-backups

# Set up backup plan for instance
```

### 6. Use VPC Parameters (Future Enhancement)

Current template uses default VPC. For production:

1. Add VPC/Subnet parameters to template
2. Implement proper network segmentation
3. Use private subnet with NAT gateway for outbound

## Maintenance

### Regular Updates

Check for AL2023 AMI updates:

```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-kernel-default-*" \
  --query 'Images | sort_by(@, &CreationDate) | [-1]'
```

The template automatically retrieves the latest AMI, so no manual updates needed.

### Long-Term Support

- AL2023 receives updates for 5+ years
- Systems Manager provides one-click patching
- CloudFormation handles version management

## Cost Estimation

### Monthly Costs (US East 1, on-demand)

| Instance | Compute | Storage | Transfer | Total |
|---|---|---|---|---|
| t3.small | $7.30 | $0.10 | ~$0.50 | ~$8/mo |
| t4g.small | $5.85 | $0.10 | ~$0.50 | ~$6/mo |
| m5.large | $70.08 | $0.10 | ~$1.00 | ~$71/mo |
| c7g.large | $56.16 | $0.10 | ~$1.00 | ~$57/mo |

**Actual costs vary by region. Use AWS pricing calculator for accuracy.**

For significant cost reduction:
- Use Reserved Instances (30-70% discount)
- Use Savings Plans (20-40% discount)
- Consider Spot Instances for non-critical workloads (70-90% discount)

## Security Considerations

### IAM Least Privilege

Current template includes CloudWatch permissions. Remove if not needed:

```yaml
# Remove this line if CloudWatch not required
- arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

### Network Security

- Default deny all inbound traffic
- HTTP (80) allowed for demo only
- SSH (22) only if explicitly enabled
- All outbound traffic allowed (customize as needed)

### Instance Hardening

Additional hardening steps:

```bash
# Connect to instance
aws ssm start-session --target i-xxxxx

# Install security updates
sudo dnf update -y --security

# Enable SELinux
sudo semanage boolean -m --on httpd_unified

# Configure firewall
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### Credentials and Secrets

Never hardcode credentials in:
- User data
- Configuration files
- Environment variables

Use instead:
- AWS Systems Manager Parameter Store
- AWS Secrets Manager
- IAM role permissions
- CloudFormation parameters

## Advanced Topics

### Integration with Auto Scaling

This single-instance template can be used as a launch template:

```bash
# Create launch template from running instance
aws ec2 create-launch-template \
  --launch-template-name my-template \
  --launch-template-data file://launch-template-data.json
```

### Application Deployment

Post-deployment application setup options:

1. **CloudFormation Init**: Packages, files, services (current approach)
2. **CodeDeploy**: Full CI/CD integration
3. **SSM Automation**: One-click configuration changes
4. **OpsWorks**: Application-level management
5. **User Data Scripts**: Shell script execution

### Monitoring and Logging

Enable additional monitoring:

```yaml
# Add to UserData to install CloudWatch agent
Scripts:
  - |
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
```

## Support and Contribution

For issues, improvements, or questions:

1. Review template comments for implementation details
2. Check troubleshooting section above
3. Enable CloudFormation debug logging: `--debug` flag
4. Contact AWS support for account-specific issues

## License

This template is provided as-is for educational and demonstration purposes.

---

**Last Updated**: 2026
**Template Version**: 2.0 (AL2023, Session Manager, ARM64 Support)
**AWS Region Support**: All regions (adjust cost estimates accordingly)
