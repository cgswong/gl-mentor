# Changelog

## 2026-03-03 - Major Update

### Added

- **Comprehensive Makefile** for stack lifecycle management
  - Validation and linting commands
  - Stack creation, update, and deletion
  - Automated testing for all backend types
  - Wait operations for async CloudFormation operations
  - Combined workflow commands (deploy, redeploy, teardown)
  - Colorized output for better readability
  - Help system with detailed documentation

- **Flexible Backend Configuration**
  - Parameter to switch between EC2-only, Lambda-only, or both
  - Conditional resource creation based on backend type
  - Path-based routing for dual backend mode (/ec2, /lambda)

- **Security Enhancements**
  - Configurable CIDR block parameter for access control
  - IMDSv2 enforcement for EC2 metadata
  - SSM Session Manager support (no SSH keys needed)
  - Security groups with least privilege
  - Drop invalid HTTP headers on ALB

- **Latest AWS Resources**
  - Amazon Linux 2023 (AL2023) via SSM parameter
  - t3.micro instance type (free tier eligible)
  - Python 3.13 Lambda runtime (latest supported)

- **Comprehensive Documentation**
  - README.md with full deployment guide
  - QUICKSTART.md for rapid deployment
  - Inline comments throughout template
  - 12 useful CloudFormation outputs

- **Monitoring & Testing**
  - CloudWatch alarm for unhealthy targets
  - Automated endpoint testing via Makefile
  - Health check endpoint for EC2 backends
  - Lambda CloudWatch Logs integration

### Changed

- Updated template structure with clear sections
- Improved parameter descriptions and constraints
- Enhanced EC2 user data script with better error handling
- Lambda function now returns detailed HTML response
- Target group configuration optimized for each backend type

### Fixed

- Removed invalid `AWS::ElasticLoadBalancingV2::TargetGroupAttachment` resource
- Fixed Lambda target group to register targets directly
- Corrected security group references
- Added proper IAM instance profile for EC2
- Fixed health check configuration for target groups

### Removed

- Hardcoded values replaced with parameters
- Outdated Lambda runtime (nodejs14.x)
- Outdated AMI reference (Amazon Linux 2)
- Inline IAM policies (now using managed policies)

## Template Features

### Parameters

- `VpcId` - VPC for resource deployment
- `PublicSubnet1` - First AZ subnet for ALB
- `PublicSubnet2` - Second AZ subnet for ALB
- `BackendType` - EC2Only, LambdaOnly, or EC2AndLambda
- `AllowedCidrBlock` - CIDR for ALB access control
- `LatestAL2023AmiId` - Auto-resolved via SSM

### Conditions

- `CreateEC2Resources` - Create EC2 backend
- `CreateLambdaResources` - Create Lambda backend
- `CreateBothBackends` - Create both with routing

### Resources Created (varies by BackendType)

#### Always Created

- Application Load Balancer
- ALB Security Group
- ALB Listener (HTTP:80)

#### EC2 Backend (EC2Only or EC2AndLambda)

- EC2 Instance (t3.micro, AL2023)
- EC2 Security Group
- EC2 IAM Role & Instance Profile
- EC2 Target Group
- CloudWatch Alarm

#### Lambda Backend (LambdaOnly or EC2AndLambda)

- Lambda Function (Python 3.13)
- Lambda Execution Role
- Lambda Target Group
- Lambda Invoke Permission

#### Dual Backend (EC2AndLambda)

- Listener Rules for path-based routing
- Both EC2 and Lambda resources

### Outputs

- LoadBalancerDNS
- LoadBalancerURL
- LoadBalancerArn
- ALBSecurityGroupId
- BackendConfiguration
- EC2InstanceId (conditional)
- EC2TargetGroupArn (conditional)
- EC2AccessPath (conditional)
- LambdaFunctionArn (conditional)
- LambdaTargetGroupArn (conditional)
- LambdaAccessPath (conditional)
- UsageInstructions

## Makefile Commands

### Validation

- `make validate` - Validate template syntax
- `make lint` - Run cfn-lint

### Stack Management

- `make create` - Create new stack
- `make update` - Update existing stack
- `make delete` - Delete stack (with confirmation)
- `make status` - Show stack status
- `make describe` - Show detailed info

### Information

- `make outputs` - Display outputs
- `make events` - Show recent events
- `make logs` - Show Lambda logs

### Testing

- `make test` - Run all tests
- `make test-ec2` - Test EC2 endpoint
- `make test-lambda` - Test Lambda endpoint
- `make test-health` - Test health check

### Workflows

- `make deploy` - Full deployment
- `make redeploy` - Full update
- `make teardown` - Full deletion

## Migration Guide

### From Old Template

If you have an existing stack using the old template:

1. **Backup current stack**

   ```bash
   aws cloudformation get-template \
     --stack-name your-stack \
     --query 'TemplateBody' > old-template-backup.yaml
   ```

2. **Export current parameters**

   ```bash
   aws cloudformation describe-stacks \
     --stack-name your-stack \
     --query 'Stacks[0].Parameters' > old-params-backup.json
   ```

3. **Create new parameter file**
   - Copy `parameters-example.json`
   - Update with your VPC and subnet IDs
   - Choose backend type

4. **Deploy new stack** (recommended: new stack name)

   ```bash
   make create stack-name=new-alb-stack
   ```

5. **Test new stack**

   ```bash
   make test stack-name=new-alb-stack
   ```

6. **Delete old stack** (after verification)

   ```bash
   aws cloudformation delete-stack --stack-name old-stack
   ```

### Breaking Changes

- Stack name parameter changed from `ExistingVpcId` to `VpcId`
- Subnet parameters renamed to `PublicSubnet1` and `PublicSubnet2`
- New required parameter: `BackendType`
- New optional parameter: `AllowedCidrBlock`
- Lambda runtime changed from nodejs14.x to python3.13
- EC2 AMI changed from Amazon Linux 2 to Amazon Linux 2023
- EC2 instance type changed from t2.micro to t3.micro

## Best Practices Implemented

1. **Security**
   - Least privilege IAM roles
   - Security groups with minimal access
   - IMDSv2 for EC2 metadata
   - SSM Session Manager instead of SSH

2. **Reliability**
   - Health checks configured
   - Graceful shutdown with deregistration delay
   - CloudWatch alarms for monitoring
   - Multi-AZ ALB deployment

3. **Cost Optimization**
   - Free tier eligible resources
   - Minimal resource configuration
   - Efficient Lambda memory allocation

4. **Operational Excellence**
   - Comprehensive documentation
   - Automated testing
   - Infrastructure as Code
   - Version control friendly

5. **Performance**
   - Latest runtimes and AMIs
   - Optimized target group settings
   - Efficient health check intervals

## Future Enhancements

Potential improvements for future versions:

- [ ] HTTPS support with ACM certificates
- [ ] Auto Scaling Group for EC2 backends
- [ ] Multiple Lambda functions with weighted routing
- [ ] Custom domain with Route 53
- [ ] WAF integration for security
- [ ] CloudWatch dashboard
- [ ] X-Ray tracing
- [ ] VPC Flow Logs
- [ ] S3 access logs for ALB
- [ ] SNS notifications for alarms
- [ ] Blue/green deployment support
- [ ] Multi-region deployment

## Support

For issues or questions:

- Review the README.md for detailed documentation
- Check QUICKSTART.md for common scenarios
- Use `make help` for Makefile commands
- Check CloudWatch Logs for errors
- Review stack events with `make events`
