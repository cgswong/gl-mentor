.PHONY: help validate deploy update describe delete cleanup list outputs logs delete-policy

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;36m
NC := \033[0m # No Color

# Default configuration
STACK_NAME ?= demo-ec2
TEMPLATE_FILE ?= template.cfn.yaml
PARAMETER_FILE ?= parameters.json
REGION ?= us-east-1
PROFILE ?= default
CAPABILITIES ?= CAPABILITY_NAMED_IAM

# Stack configuration defaults (can be overridden)
INSTANCE_TYPE ?= t3.small
CIDR_ACCESS ?= 0.0.0.0/0

# Display help information
help:
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)EC2 CloudFormation Stack Management - Makefile Targets$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)USAGE:$(NC)"
	@echo "  make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "$(GREEN)TARGETS:$(NC)"
	@echo ""
	@echo "  $(YELLOW)help$(NC)              - Display this help message"
	@echo "  $(YELLOW)validate$(NC)          - Validate CloudFormation template syntax"
	@echo "  $(YELLOW)deploy$(NC)            - Create or update CloudFormation stack"
	@echo "  $(YELLOW)update$(NC)            - Update existing CloudFormation stack"
	@echo "  $(YELLOW)describe$(NC)          - Describe stack resources and status"
	@echo "  $(YELLOW)outputs$(NC)           - Display stack outputs"
	@echo "  $(YELLOW)logs$(NC)              - Show cloud-init logs from instance"
	@echo "  $(YELLOW)events$(NC)            - Watch CloudFormation stack events"
	@echo "  $(YELLOW)delete$(NC)            - Delete CloudFormation stack"
	@echo "  $(YELLOW)cleanup$(NC)           - Alias for delete"
	@echo "  $(YELLOW)list$(NC)              - List all stacks in region"
	@echo "  $(YELLOW)cost$(NC)              - Estimate stack costs"
	@echo "  $(YELLOW)ssh-connect$(NC)       - Connect via SSH (requires KeyName)"
	@echo "  $(YELLOW)session-connect$(NC)   - Connect via Session Manager (recommended)"
	@echo ""
	@echo "$(GREEN)PARAMETERS:$(NC)"
	@echo ""
	@echo "  $(YELLOW)STACK_NAME$(NC)        - CloudFormation stack name"
	@echo "                  Default: $(GREEN)$(STACK_NAME)$(NC)"
	@echo "                  Example: make deploy STACK_NAME=my-stack"
	@echo ""
	@echo "  $(YELLOW)TEMPLATE_FILE$(NC)     - CloudFormation template path"
	@echo "                  Default: $(GREEN)$(TEMPLATE_FILE)$(NC)"
	@echo "                  Example: make validate TEMPLATE_FILE=template.cfn.yaml"
	@echo ""
	@echo "  $(YELLOW)PARAMETER_FILE$(NC)    - Parameter file (JSON) path"
	@echo "                  Default: $(GREEN)$(PARAMETER_FILE)$(NC)"
	@echo "                  Format: [{"ParameterKey":"KeyName","ParameterValue":"value"}]"
	@echo ""
	@echo "  $(YELLOW)INSTANCE_TYPE$(NC)     - EC2 instance type"
	@echo "                  Default: $(GREEN)$(INSTANCE_TYPE)$(NC)"
	@echo "                  Options: t3.nano, t3.small, t4g.small, m5.large, m7g.xlarge"
	@echo ""
	@echo "  $(YELLOW)CIDR_ACCESS$(NC)        - IP CIDR range for HTTP access"
	@echo "                  Default: $(GREEN)$(CIDR_ACCESS)$(NC)"
	@echo "                  Example: make deploy CIDR_ACCESS=192.168.1.0/24"
	@echo ""
	@echo "  $(YELLOW)REGION$(NC)             - AWS region"
	@echo "                  Default: $(GREEN)$(REGION)$(NC)"
	@echo "                  Example: make deploy REGION=us-west-2"
	@echo ""
	@echo "  $(YELLOW)PROFILE$(NC)            - AWS CLI profile"
	@echo "                  Default: $(GREEN)$(PROFILE)$(NC)"
	@echo "                  Example: make deploy PROFILE=production"
	@echo ""
	@echo "$(GREEN)EXAMPLES:$(NC)"
	@echo ""
	@echo "  # Deploy with default parameters"
	@echo "  $(YELLOW)make deploy$(NC)"
	@echo ""
	@echo "  # Deploy cost-optimized ARM64 instance"
	@echo "  $(YELLOW)make deploy INSTANCE_TYPE=t4g.small$(NC)"
	@echo ""
	@echo "  # Deploy with CIDR access set to local network"
	@echo "  $(YELLOW)make deploy INSTANCE_TYPE=t3.medium CIDR_ACCESS=192.168.1.0/24$(NC)"
	@echo ""
	@echo "  # Deploy with custom stack name"
	@echo "  $(YELLOW)make deploy STACK_NAME=custom-stack-name INSTANCE_TYPE=m5.large$(NC)"
	@echo ""
	@echo "  # Deploy to different region with specific profile"
	@echo "  $(YELLOW)make deploy REGION=eu-west-1 PROFILE=eu-account$(NC)"
	@echo ""
	@echo "  # Validate template before deployment"
	@echo "  $(YELLOW)make validate$(NC)"
	@echo ""
	@echo "  # Update existing stack with new instance type"
	@echo "  $(YELLOW)make update INSTANCE_TYPE=t3.large$(NC)"
	@echo ""
	@echo "  # Connect to instance via Session Manager"
	@echo "  $(YELLOW)make session-connect$(NC)"
	@echo ""
	@echo "  # View stack outputs"
	@echo "  $(YELLOW)make outputs$(NC)"
	@echo ""
	@echo "  # Monitor stack events during deployment"
	@echo "  $(YELLOW)make events$(NC)"
	@echo ""
	@echo "  # Estimate deployment costs"
	@echo "  $(YELLOW)make cost INSTANCE_TYPE=m5.xlarge$(NC)"
	@echo ""
	@echo "  # Clean up stack when done"
	@echo "  $(YELLOW)make cleanup$(NC)"
	@echo ""
	@echo "$(GREEN)QUICK REFERENCE:$(NC)"
	@echo ""
	@echo "  1. $(BLUE)make validate$(NC)              # Syntax check"
	@echo "  2. $(BLUE)make deploy$(NC)                # Create stack"
	@echo "  3. $(BLUE)make outputs$(NC)               # View connection info"
	@echo "  4. $(BLUE)make session-connect$(NC)       # Open terminal session"
	@echo "  5. $(BLUE)make cleanup$(NC)               # Delete stack"
	@echo ""
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"

# Validate CloudFormation template syntax
validate:
	@echo "$(BLUE)Validating CloudFormation template...$(NC)"
	@aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) \
		--profile $(PROFILE) 2>&1 | tee /tmp/validate-output.json
	@echo "$(GREEN)✓ Template validation successful$(NC)"

# Deploy CloudFormation stack (create or update)
deploy: validate
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)Deploying CloudFormation Stack: $(STACK_NAME)$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Stack Name:$(NC) $(STACK_NAME)"
	@echo "$(YELLOW)Region:$(NC) $(REGION)"
	@echo "$(YELLOW)Instance Type:$(NC) $(INSTANCE_TYPE)"
	@echo "$(YELLOW)CIDR Access:$(NC) $(CIDR_ACCESS)"
	@echo ""
	@read -p "Press Enter to continue deployment or Ctrl+C to cancel..." dummy
	@aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--capabilities $(CAPABILITIES) \
		    --parameter-overrides \
			    InstanceType=$(INSTANCE_TYPE) \
			    CidrAccess=$(CIDR_ACCESS) \
		--tags \
			environment=sbx \
			managed-by=Makefile \
			create-date=$$(date +%Y-%m-%d) \
		--no-fail-on-empty-changeset
	@echo ""
	@echo "$(GREEN)✓ Stack deployment initiated or completed successfully$(NC)"
	@echo ""
	@echo "$(YELLOW)To view stack status:$(NC)"
	@echo "  make describe"
	@echo ""
	@echo "$(YELLOW)To view outputs:$(NC)"
	@echo "  make outputs"
	@echo ""

# Update existing CloudFormation stack
update: validate
	@echo "$(BLUE)Updating CloudFormation Stack: $(STACK_NAME)$(NC)"
	@echo "$(YELLOW)Instance Type:$(NC) $(INSTANCE_TYPE)"
	@echo "$(YELLOW)CIDR Access:$(NC) $(CIDR_ACCESS)"
	@echo ""
	@read -p "Press Enter to continue update or Ctrl+C to cancel..." dummy
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--capabilities $(CAPABILITIES) \
		--parameters \
			ParameterKey=InstanceType,ParameterValue=$(INSTANCE_TYPE) \
			ParameterKey=CidrAccess,ParameterValue=$(CIDR_ACCESS) || true
	@echo ""
	@echo "$(GREEN)✓ Stack update initiated$(NC)"
	@echo ""
	@echo "$(YELLOW)To monitor update progress:$(NC)"
	@echo "  make events"
	@echo ""

# Describe stack resources and status
describe:
	@echo "$(BLUE)Stack Status: $(STACK_NAME)$(NC)"
	@echo ""
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].{StackName:StackName,StackStatus:StackStatus,CreationTime:CreationTime,LastUpdatedTime:LastUpdatedTime,StackId:StackId}' \
		--output table
	@echo ""
	@echo "$(BLUE)Stack Resources:$(NC)"
	@echo ""
	@aws cloudformation describe-stack-resources \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'StackResources[].{LogicalId:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}' \
		--output table
	@echo ""

# Display stack outputs
outputs:
	@echo "$(BLUE)Stack Outputs: $(STACK_NAME)$(NC)"
	@echo ""
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].Outputs[].[OutputKey,OutputValue,Description]' \
		--output table
	@echo ""

# Connect via SSH (requires KeyName and public IP)
ssh-connect:
	@echo "$(BLUE)Connecting via SSH...$(NC)"
	@INSTANCE_ID=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
		--output text); \
	PUBLIC_IP=$$(aws ec2 describe-instances \
		--instance-ids $$INSTANCE_ID \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Reservations[0].Instances[0].PublicIpAddress' \
		--output text); \
	if [ -z "$$PUBLIC_IP" ] || [ "$$PUBLIC_IP" = "None" ]; then \
		echo "$(RED)✗ No public IP found. Instance may be starting or SSH not enabled.$(NC)"; \
		echo "Use 'make session-connect' instead."; \
		exit 1; \
	fi; \
	echo "$(GREEN)Connecting to: $$PUBLIC_IP$(NC)"; \
	ssh -i ~/.ssh/$(if $(KEY_NAME),$(KEY_NAME),id_rsa) ec2-user@$$PUBLIC_IP || true

# Connect via Session Manager (recommended)
session-connect:
	@echo "$(BLUE)Connecting via Session Manager...$(NC)"
	@INSTANCE_ID=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
		--output text); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "$(RED)✗ Could not retrieve instance ID$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Starting session with: $$INSTANCE_ID$(NC)"; \
	aws ssm start-session \
		--target $$INSTANCE_ID \
		--region $(REGION) \
		--profile $(PROFILE)

# Display OS logs from instance
logs:
	@echo "$(BLUE)Retrieving messages logs...$(NC)"
	@INSTANCE_ID=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
		--output text); \
	aws ssm start-session \
		--target $$INSTANCE_ID \
		--region $(REGION) \
		--profile $(PROFILE) \
		--document-name "AWS-RunShellScript" \
		--parameters '{"command":["tail -100 /var/log/messages"]}' || true

# Watch CloudFormation stack events
events:
	@echo "$(BLUE)Watching CloudFormation events for: $(STACK_NAME)$(NC)"
	@while true; do \
		clear; \
		echo "$(BLUE)Stack Events (refreshing every 5 seconds, press Ctrl+C to exit)$(NC)"; \
		echo ""; \
		aws cloudformation describe-stack-events \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE) \
			--query 'StackEvents[0:15].[Timestamp,LogicalResourceId,ResourceType,ResourceStatus,ResourceStatusReason]' \
			--output table; \
		sleep 5; \
	done

# Delete CloudFormation stack
delete: delete-policy
	@echo "$(RED)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(RED)WARNING: Deleting stack will remove all resources$(NC)"
	@echo "$(RED)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Stack Name:$(NC) $(STACK_NAME)"
	@echo "$(YELLOW)Region:$(NC) $(REGION)"
	@echo ""
	@read -p "Type 'DELETE' to confirm stack deletion or press Ctrl+C to cancel: " confirm; \
	if [ "$$confirm" = "DELETE" ]; then \
		echo ""; \
		echo "$(RED)Deleting stack...$(NC)"; \
		aws cloudformation delete-stack \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE); \
		echo "$(GREEN)✓ Stack deletion initiated$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Waiting for stack deletion to complete (this may take a few minutes)...$(NC)"; \
		aws cloudformation wait stack-delete-complete \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE) 2>/dev/null && \
		echo "$(GREEN)✓ Stack deleted successfully$(NC)" || \
		echo "$(YELLOW)Stack deletion in progress, check status with: make describe$(NC)"; \
	else \
		echo "$(YELLOW)Deletion cancelled$(NC)"; \
		exit 1; \
	fi

# Alias for delete
cleanup: delete

# Helper to delete delete protection policy if exists
delete-policy:
	@STACK_ID=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].StackId' \
		--output text 2>/dev/null) || true; \
	if [ ! -z "$$STACK_ID" ]; then \
		aws cloudformation delete-stack-policy \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE) 2>/dev/null || true; \
	fi

# List all stacks in region
list:
	@echo "$(BLUE)CloudFormation Stacks in Region: $(REGION)$(NC)"
	@echo ""
	@aws cloudformation list-stacks \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'StackSummaries[].[StackName,StackStatus,CreationTime]' \
		--output table
	@echo ""

# Estimate costs
cost:
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)COST ESTIMATION for Instance Type: $(INSTANCE_TYPE) in Region: $(REGION)$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Monthly Cost Estimates (approximate on-demand pricing):$(NC)"
	@echo ""
	@echo "  t3.nano       ~  $3.50/month"
	@echo "  t3.micro      ~  $7.00/month"
	@echo "  t3.small      ~  $8.50/month"
	@echo "  t3.medium     ~ $17.00/month"
	@echo "  t3.large      ~ $34.00/month"
	@echo ""
	@echo "  t4g.nano      ~  $2.50/month  (ARM64 - 30% cheaper)"
	@echo "  t4g.micro     ~  $5.00/month  (ARM64 - 30% cheaper)"
	@echo "  t4g.small     ~  $6.00/month  (ARM64 - 30% cheaper)"
	@echo "  t4g.medium    ~ $12.00/month  (ARM64 - 30% cheaper)"
	@echo "  t4g.large     ~ $24.00/month  (ARM64 - 30% cheaper)"
	@echo ""
	@echo "  m5.large      ~ $70.00/month"
	@echo "  m5.xlarge     ~$140.00/month"
	@echo ""
	@echo "  m7g.large     ~ $50.00/month  (ARM64 - 30% cheaper)"
	@echo "  m7g.xlarge    ~$100.00/month  (ARM64 - 30% cheaper)"
	@echo ""
	@echo "$(YELLOW)Additional charges:$(NC)"
	@echo "  • EBS Storage (8GB default): ~$0.80/month (gp2) or ~$0.64/month (gp3)"
	@echo "  • Data Transfer out: Varies by amount"
	@echo ""
	@echo "$(YELLOW)Cost Reduction Options:$(NC)"
	@echo "  • Reserved Instances: 30-70% discount (1-3 year commitment)"
	@echo "  • Savings Plans: 20-40% discount (1-3 year compute commitment)"
	@echo "  • Spot Instances: 70-90% discount (interruption risk)"
	@echo ""
	@echo "$(YELLOW)For accurate pricing, visit:$(NC)"
	@echo "  https://calculator.aws/#/"
	@echo ""
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"

# Default target
.DEFAULT_GOAL := help
