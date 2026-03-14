.PHONY: help validate deploy update describe delete cleanup list outputs events

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;36m
NC := \033[0m

# Default configuration
STACK_NAME ?= demo-vpc
TEMPLATE_FILE ?= template.cfn.yaml
PARAMETER_FILE ?= parameters.json
REGION ?= us-east-1
PROFILE ?= default
CAPABILITIES ?= CAPABILITY_IAM

# VPC configuration defaults (can be overridden)
VPC_CIDR ?= 10.0.0.0/16
NUMBER_OF_AZS ?= 2
AZ_ID_1 ?= use1-az1
AZ_ID_2 ?= use1-az2
AZ_ID_3 ?= use1-az4
ENABLE_NAT ?= no
ENABLE_FLOW_LOG ?= no

help:
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)VPC CloudFormation Stack Management$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)USAGE:$(NC)"
	@echo "  make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "$(GREEN)TARGETS:$(NC)"
	@echo "  $(YELLOW)help$(NC)              - Display this help message"
	@echo "  $(YELLOW)validate$(NC)          - Validate CloudFormation template"
	@echo "  $(YELLOW)deploy$(NC)            - Deploy VPC stack (create or update)"
	@echo "  $(YELLOW)deploy-with-params$(NC) - Deploy using parameters.json file"
	@echo "  $(YELLOW)update$(NC)            - Update existing stack"
	@echo "  $(YELLOW)describe$(NC)          - Show stack status and resources"
	@echo "  $(YELLOW)outputs$(NC)           - Display stack outputs"
	@echo "  $(YELLOW)events$(NC)            - Watch stack events"
	@echo "  $(YELLOW)delete$(NC)            - Delete stack"
	@echo "  $(YELLOW)cleanup$(NC)           - Alias for delete"
	@echo "  $(YELLOW)list$(NC)              - List all stacks"
	@echo ""
	@echo "$(GREEN)PARAMETERS:$(NC)"
	@echo "  $(YELLOW)STACK_NAME$(NC)        - Stack name (default: $(GREEN)$(STACK_NAME)$(NC))"
	@echo "  $(YELLOW)VPC_CIDR$(NC)          - VPC CIDR block (default: $(GREEN)$(VPC_CIDR)$(NC))"
	@echo "  $(YELLOW)NUMBER_OF_AZS$(NC)     - Number of AZs: 2 or 3 (default: $(GREEN)$(NUMBER_OF_AZS)$(NC))"
	@echo "  $(YELLOW)AZ_ID_1$(NC)           - First AZ ID (default: $(GREEN)$(AZ_ID_1)$(NC))"
	@echo "  $(YELLOW)AZ_ID_2$(NC)           - Second AZ ID (default: $(GREEN)$(AZ_ID_2)$(NC))"
	@echo "  $(YELLOW)AZ_ID_3$(NC)           - Third AZ ID (default: $(GREEN)$(AZ_ID_3)$(NC))"
	@echo "  $(YELLOW)ENABLE_NAT$(NC)        - Enable NAT Gateway: yes/no (default: $(GREEN)$(ENABLE_NAT)$(NC))"
	@echo "  $(YELLOW)ENABLE_FLOW_LOG$(NC)   - Enable Flow Logs: no/cloudwatch/s3 (default: $(GREEN)$(ENABLE_FLOW_LOG)$(NC))"
	@echo "  $(YELLOW)REGION$(NC)            - AWS region (default: $(GREEN)$(REGION)$(NC))"
	@echo "  $(YELLOW)PROFILE$(NC)           - AWS profile (default: $(GREEN)$(PROFILE)$(NC))"
	@echo ""
	@echo "$(GREEN)EXAMPLES:$(NC)"
	@echo "  # Deploy basic 2-AZ VPC"
	@echo "  $(YELLOW)make deploy$(NC)"
	@echo ""
	@echo "  # Deploy 3-AZ VPC with NAT Gateway"
	@echo "  $(YELLOW)make deploy NUMBER_OF_AZS=3 ENABLE_NAT=yes$(NC)"
	@echo ""
	@echo "  # Deploy with CloudWatch Flow Logs"
	@echo "  $(YELLOW)make deploy ENABLE_FLOW_LOG=cloudwatch$(NC)"
	@echo ""
	@echo "  # Deploy using parameter file"
	@echo "  $(YELLOW)make deploy-with-params$(NC)"
	@echo ""
	@echo "  # Deploy to different region"
	@echo "  $(YELLOW)make deploy REGION=us-west-2 AZ_ID_1=usw2-az1 AZ_ID_2=usw2-az2$(NC)"
	@echo ""
	@echo "  # View outputs"
	@echo "  $(YELLOW)make outputs$(NC)"
	@echo ""
	@echo "  # Delete stack"
	@echo "  $(YELLOW)make delete$(NC)"
	@echo ""
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"

validate:
	@echo "$(BLUE)Validating CloudFormation template...$(NC)"
	@aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) \
		--profile $(PROFILE) > /dev/null
	@echo "$(GREEN)✓ Template validation successful$(NC)"

deploy: validate
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)Deploying VPC Stack: $(STACK_NAME)$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Stack Name:$(NC) $(STACK_NAME)"
	@echo "$(YELLOW)Region:$(NC) $(REGION)"
	@echo "$(YELLOW)VPC CIDR:$(NC) $(VPC_CIDR)"
	@echo "$(YELLOW)Number of AZs:$(NC) $(NUMBER_OF_AZS)"
	@echo "$(YELLOW)NAT Gateway:$(NC) $(ENABLE_NAT)"
	@echo "$(YELLOW)Flow Logs:$(NC) $(ENABLE_FLOW_LOG)"
	@echo ""
	@aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--capabilities $(CAPABILITIES) \
		--parameter-overrides \
			VPCCidr=$(VPC_CIDR) \
			NumberOfAZs=$(NUMBER_OF_AZS) \
			AvailabilityZoneId1=$(AZ_ID_1) \
			AvailabilityZoneId2=$(AZ_ID_2) \
			AvailabilityZoneId3=$(AZ_ID_3) \
			EnableNATGateway=$(ENABLE_NAT) \
			EnableVPCFlowLog=$(ENABLE_FLOW_LOG) \
		--tags \
			environment=demo \
			managed-by=Makefile \
			create-date=$$(date +%Y-%m-%d) \
		--no-fail-on-empty-changeset
	@echo ""
	@echo "$(GREEN)✓ Stack deployment completed$(NC)"
	@echo ""
	@echo "$(YELLOW)View outputs:$(NC) make outputs"

deploy-with-params: validate
	@echo "$(BLUE)Deploying VPC Stack with parameter file: $(STACK_NAME)$(NC)"
	@aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--capabilities $(CAPABILITIES) \
		--parameter-overrides file://$(PARAMETER_FILE) \
		--tags \
			environment=demo \
			managed-by=Makefile \
			create-date=$$(date +%Y-%m-%d) \
		--no-fail-on-empty-changeset
	@echo "$(GREEN)✓ Stack deployment completed$(NC)"

update: validate
	@echo "$(BLUE)Updating VPC Stack: $(STACK_NAME)$(NC)"
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--capabilities $(CAPABILITIES) \
		--parameters \
			ParameterKey=VPCCidr,ParameterValue=$(VPC_CIDR) \
			ParameterKey=NumberOfAZs,ParameterValue=$(NUMBER_OF_AZS) \
			ParameterKey=AvailabilityZoneId1,ParameterValue=$(AZ_ID_1) \
			ParameterKey=AvailabilityZoneId2,ParameterValue=$(AZ_ID_2) \
			ParameterKey=AvailabilityZoneId3,ParameterValue=$(AZ_ID_3) \
			ParameterKey=EnableNATGateway,ParameterValue=$(ENABLE_NAT) \
			ParameterKey=EnableVPCFlowLog,ParameterValue=$(ENABLE_FLOW_LOG) || true
	@echo "$(GREEN)✓ Stack update initiated$(NC)"

describe:
	@echo "$(BLUE)Stack Status: $(STACK_NAME)$(NC)"
	@echo ""
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].{StackName:StackName,Status:StackStatus,Created:CreationTime}' \
		--output table
	@echo ""
	@echo "$(BLUE)Stack Resources:$(NC)"
	@aws cloudformation describe-stack-resources \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'StackResources[].{Resource:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}' \
		--output table

outputs:
	@echo "$(BLUE)Stack Outputs: $(STACK_NAME)$(NC)"
	@echo ""
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--profile $(PROFILE) \
		--query 'Stacks[0].Outputs[].[OutputKey,OutputValue,Description]' \
		--output table

events:
	@echo "$(BLUE)Watching stack events: $(STACK_NAME)$(NC)"
	@echo "Press Ctrl+C to stop"
	@echo ""
	@while true; do \
		aws cloudformation describe-stack-events \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE) \
			--max-items 10 \
			--query 'StackEvents[].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' \
			--output table; \
		sleep 5; \
		clear; \
	done

delete:
	@echo "$(RED)WARNING: This will delete the VPC stack: $(STACK_NAME)$(NC)"
	@read -p "Type stack name to confirm deletion: " confirm; \
	if [ "$$confirm" = "$(STACK_NAME)" ]; then \
		echo "$(BLUE)Deleting stack...$(NC)"; \
		aws cloudformation delete-stack \
			--stack-name $(STACK_NAME) \
			--region $(REGION) \
			--profile $(PROFILE); \
		echo "$(GREEN)✓ Stack deletion initiated$(NC)"; \
		echo "$(YELLOW)Monitor progress:$(NC) make events"; \
	else \
		echo "$(RED)Deletion cancelled - name did not match$(NC)"; \
	fi

cleanup: delete

list:
	@echo "$(BLUE)CloudFormation Stacks in $(REGION):$(NC)"
	@aws cloudformation list-stacks \
		--region $(REGION) \
		--profile $(PROFILE) \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--query 'StackSummaries[].[StackName,StackStatus,CreationTime]' \
		--output table
