# Deployment Checklist

Use this checklist to ensure a successful deployment of the Auto Scaling CloudFormation stack.

## Pre-Deployment

### 1. Prerequisites Check
- [ ] AWS CLI installed and configured
- [ ] AWS credentials configured (`aws configure`)
- [ ] Appropriate IAM permissions for CloudFormation, EC2, VPC, ELB, IAM, SNS
- [ ] Valid email address for notifications
- [ ] Sufficient service limits (VPCs, EIPs, NAT Gateways, etc.)

### 2. Configuration Review
- [ ] Review `parameters.json` and update values
- [ ] Update `OperatorEmail` with your email address
- [ ] Choose appropriate `InstanceType` for your workload
- [ ] Select `InstanceArchitecture` (arm64 recommended for cost savings)
- [ ] Set `MinSize`, `MaxSize`, and `DesiredCapacity` appropriately
- [ ] Review estimated costs in README.md

### 3. Template Validation
- [ ] Run `make validate` - should pass
- [ ] Run `make lint` - should pass (if cfn-lint installed)
- [ ] Run `make test` - all tests should pass
- [ ] Run `./test.sh` - comprehensive test suite should pass

### 4. Documentation Review
- [ ] Read [README.md](README.md) - understand architecture
- [ ] Read [QUICKSTART.md](QUICKSTART.md) - understand deployment process
- [ ] Review [CHANGELOG.md](CHANGELOG.md) - understand changes from v1.0

## Deployment

### 5. Initial Deployment
- [ ] Run `make deploy` or `make create`
- [ ] Monitor deployment: `make events`
- [ ] Wait for completion: `make wait-complete` (3-5 minutes)
- [ ] Check status: `make status`
- [ ] Verify outputs: `make outputs`

### 6. Email Confirmation
- [ ] Check email for SNS subscription confirmation
- [ ] Click confirmation link in email
- [ ] Verify subscription in AWS Console (SNS → Topics)

### 7. Application Verification
- [ ] Get ALB URL: `make get-url`
- [ ] Open in browser: `make open-url`
- [ ] Verify web page loads correctly
- [ ] Check instance metadata displays correctly
- [ ] Refresh multiple times to verify load balancing

### 8. Health Check Verification
```bash
# Get target group ARN
TARGET_GROUP_ARN=$(aws cloudformation describe-stacks \
  --stack-name autoscaling-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupARN`].OutputValue' \
  --output text)

# Check target health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```
- [ ] All targets show `healthy` state
- [ ] Target count matches `DesiredCapacity`

### 9. Session Manager Access Test
```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=autoscaling-demo-asg" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

# Connect to an instance
aws ssm start-session --target <instance-id>
```
- [ ] Can list instances
- [ ] Can connect via Session Manager
- [ ] No SSH key required

## Post-Deployment

### 10. Monitoring Setup
- [ ] Verify CloudWatch alarms exist: `make resources | grep Alarm`
- [ ] Check alarm states in CloudWatch Console
- [ ] Verify SNS topic has email subscription
- [ ] Test notification by manually triggering alarm (optional)

### 11. Auto Scaling Test (Optional)
```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# Generate CPU load
yes > /dev/null &
yes > /dev/null &

# Monitor in another terminal
watch -n 5 "make events | head -20"
```
- [ ] CPU utilization increases
- [ ] Scale-up alarm triggers after 5 minutes
- [ ] New instance launches
- [ ] Email notification received
- [ ] Kill load processes: `killall yes`
- [ ] Scale-down alarm triggers after 10 minutes
- [ ] Instance terminates
- [ ] Email notification received

### 12. Documentation
- [ ] Document stack name and region
- [ ] Save ALB URL for reference
- [ ] Document any customizations made
- [ ] Share access instructions with team

### 13. Cost Monitoring
- [ ] Enable AWS Cost Explorer (if not already enabled)
- [ ] Set up billing alerts
- [ ] Tag resources for cost allocation
- [ ] Review estimated monthly costs

## Production Readiness (Optional)

### 14. Security Enhancements
- [ ] Request ACM certificate for custom domain
- [ ] Add HTTPS listener to ALB
- [ ] Redirect HTTP to HTTPS
- [ ] Enable ALB access logs to S3
- [ ] Enable VPC Flow Logs
- [ ] Review security group rules

### 15. Monitoring Enhancements
- [ ] Create CloudWatch Dashboard
- [ ] Add custom CloudWatch metrics
- [ ] Set up CloudWatch Logs for application logs
- [ ] Configure AWS X-Ray (optional)
- [ ] Set up additional alarms (memory, disk, network)

### 16. Backup and DR
- [ ] Enable automated EBS snapshots
- [ ] Document disaster recovery procedures
- [ ] Test stack recreation from template
- [ ] Consider multi-region deployment

### 17. Performance Optimization
- [ ] Review instance types based on actual usage
- [ ] Adjust Auto Scaling thresholds
- [ ] Consider Reserved Instances or Savings Plans
- [ ] Optimize application code
- [ ] Enable CloudFront (if needed)

## Troubleshooting

### Common Issues

#### Stack Creation Failed
```bash
# Check events
make events

# Check specific resource
aws cloudformation describe-stack-resources \
  --stack-name autoscaling-demo \
  --logical-resource-id <ResourceId>
```

#### Instances Not Healthy
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>

# Check instance logs
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/httpd/error_log
```

#### Cannot Access Application
- [ ] Verify ALB DNS resolves: `nslookup <alb-dns>`
- [ ] Check security groups: `make resources | grep SecurityGroup`
- [ ] Verify target health: see above
- [ ] Check ALB listener: `make describe`

#### Session Manager Not Working
- [ ] Verify IAM role attached to instances
- [ ] Check SSM agent status: `systemctl status amazon-ssm-agent`
- [ ] Verify VPC endpoints (if using private subnets without NAT)
- [ ] Check IAM permissions for your user

## Cleanup

### When Testing is Complete
```bash
# Delete stack
make delete

# Confirm deletion
# Type 'y' when prompted

# Wait for deletion to complete
make wait-delete

# Verify deletion
aws cloudformation list-stacks \
  --stack-status-filter DELETE_COMPLETE \
  --query 'StackSummaries[?StackName==`autoscaling-demo`]'
```

### Manual Cleanup (if needed)
If stack deletion fails, manually delete:
- [ ] NAT Gateway Elastic IPs (may take 5-10 minutes to release)
- [ ] ENIs (Elastic Network Interfaces)
- [ ] Security Groups (delete in correct order)
- [ ] VPC (after all resources deleted)

## Success Criteria

✅ All checklist items completed
✅ Stack status: `CREATE_COMPLETE` or `UPDATE_COMPLETE`
✅ All instances healthy in target group
✅ Application accessible via ALB URL
✅ Session Manager access working
✅ Email notifications received
✅ Auto Scaling tested (optional)
✅ Documentation updated

## Support

- **Documentation**: [README.md](README.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Changes**: [CHANGELOG.md](CHANGELOG.md)
- **Migration**: [MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md)
- **Commands**: `make help`

## Notes

Use this space to document deployment-specific information:

```
Stack Name: ___________________________
Region: ___________________________
Deployment Date: ___________________________
ALB URL: ___________________________
Deployed By: ___________________________
Purpose: ___________________________
Custom Changes: ___________________________
___________________________
___________________________
```

---

**Deployment Status**: [ ] Not Started [ ] In Progress [ ] Complete [ ] Failed

**Last Updated**: ___________________________
