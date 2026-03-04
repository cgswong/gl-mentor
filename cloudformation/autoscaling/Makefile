# CloudFormation Stack Management Makefile
# This Makefile provides commands to manage the CloudFormation stack lifecycle

# ==================== Configuration ====================

# Default values (can be overridden via command line)
STACK_NAME ?= autoscaling-demo
TEMPLATE_FILE ?= template.cfn.yaml
PARAMETERS_FILE ?= parameters.json
REGION ?= us-east-1

# AWS CLI configuration
AWS := aws cloudformation
AWS_OPTS := --region $(REGION)

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_RED := \033[31m

# ==================== Phony Targets ====================

.PHONY: help validate lint test create update delete describe status events outputs \
        resources parameters change-set list-stacks clean deploy wait-complete \
        wait-delete estimate-cost

# ==================== Help ====================

help: ## Show this help message
	@echo "$(COLOR_BOLD)CloudFormation Stack Management$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Usage:$(COLOR_RESET)"
	@echo "  make [target] [VARIABLE=value]"
	@echo ""
	@echo "$(COLOR_BOLD)Variables:$(COLOR_RESET)"
	@echo "  $(COLOR_BLUE)STACK_NAME$(COLOR_RESET)       Stack name (default: $(STACK_NAME))"
	@echo "  $(COLOR_BLUE)TEMPLATE_FILE$(COLOR_RESET)    Template file (default: $(TEMPLATE_FILE))"
	@echo "  $(COLOR_BLUE)PARAMETERS_FILE$(COLOR_RESET)  Parameters file (default: $(PARAMETERS_FILE))"
	@echo "  $(COLOR_BLUE)REGION$(COLOR_RESET)           AWS region (default: $(REGION))"
	@echo ""
	@echo "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo "  make deploy"
	@echo "  make deploy STACK_NAME=my-stack REGION=us-west-2"
	@echo "  make delete STACK_NAME=my-stack"
	@echo "  make status"
	@echo ""
	@echo "$(COLOR_BOLD)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-18s$(COLOR_RESET) %s\n", $$1, $$2}'

# ==================== Validation and Testing ====================

validate: ## Validate CloudFormation template syntax
	@echo "$(COLOR_BLUE)Validating template: $(TEMPLATE_FILE)$(COLOR_RESET)"
	@$(AWS) validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		$(AWS_OPTS) > /dev/null
	@echo "$(COLOR_GREEN)✓ Template is valid$(COLOR_RESET)"

lint: ## Run cfn-lint on the template (requires cfn-lint to be installed)
	@echo "$(COLOR_BLUE)Linting template: $(TEMPLATE_FILE)$(COLOR_RESET)"
	@if command -v cfn-lint >/dev/null 2>&1; then \
		cfn-lint $(TEMPLATE_FILE); \
		echo "$(COLOR_GREEN)✓ Linting complete$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ cfn-lint not installed. Install with: pip install cfn-lint$(COLOR_RESET)"; \
	fi

test: validate lint ## Run all validation and linting tests
	@echo "$(COLOR_GREEN)✓ All tests passed$(COLOR_RESET)"

# ==================== Stack Operations ====================

create: validate ## Create a new CloudFormation stack
	@echo "$(COLOR_BLUE)Creating stack: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) create-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMETERS_FILE) \
		--capabilities CAPABILITY_IAM \
		--tags Key=ManagedBy,Value=Makefile \
		$(AWS_OPTS)
	@echo "$(COLOR_GREEN)✓ Stack creation initiated$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Run 'make wait-complete' to wait for completion$(COLOR_RESET)"

update: validate ## Update an existing CloudFormation stack
	@echo "$(COLOR_BLUE)Updating stack: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMETERS_FILE) \
		--capabilities CAPABILITY_IAM \
		$(AWS_OPTS) || \
	(if [ $$? -eq 254 ]; then \
		echo "$(COLOR_YELLOW)⚠ No updates to be performed$(COLOR_RESET)"; \
	else \
		exit 1; \
	fi)
	@echo "$(COLOR_GREEN)✓ Stack update initiated$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Run 'make wait-complete' to wait for completion$(COLOR_RESET)"

delete: ## Delete the CloudFormation stack
	@echo "$(COLOR_RED)Deleting stack: $(STACK_NAME)$(COLOR_RESET)"
	@read -p "Are you sure you want to delete the stack '$(STACK_NAME)'? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(AWS) delete-stack \
			--stack-name $(STACK_NAME) \
			$(AWS_OPTS); \
		echo "$(COLOR_GREEN)✓ Stack deletion initiated$(COLOR_RESET)"; \
		echo "$(COLOR_YELLOW)Run 'make wait-delete' to wait for completion$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Deletion cancelled$(COLOR_RESET)"; \
	fi

deploy: ## Deploy stack (create if doesn't exist, update if exists)
	@echo "$(COLOR_BLUE)Deploying stack: $(STACK_NAME)$(COLOR_RESET)"
	@if $(AWS) describe-stacks --stack-name $(STACK_NAME) $(AWS_OPTS) >/dev/null 2>&1; then \
		echo "$(COLOR_YELLOW)Stack exists, updating...$(COLOR_RESET)"; \
		$(MAKE) update; \
	else \
		echo "$(COLOR_YELLOW)Stack does not exist, creating...$(COLOR_RESET)"; \
		$(MAKE) create; \
	fi

# ==================== Stack Information ====================

describe: ## Describe the stack in detail
	@$(AWS) describe-stacks \
		--stack-name $(STACK_NAME) \
		$(AWS_OPTS)

status: ## Show current stack status
	@echo "$(COLOR_BLUE)Stack Status: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].[StackName,StackStatus,StackStatusReason]' \
		--output table \
		$(AWS_OPTS)

events: ## Show recent stack events
	@echo "$(COLOR_BLUE)Recent Events: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) describe-stack-events \
		--stack-name $(STACK_NAME) \
		--max-items 20 \
		--query 'StackEvents[].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
		--output table \
		$(AWS_OPTS)

outputs: ## Show stack outputs
	@echo "$(COLOR_BLUE)Stack Outputs: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].Outputs[].[OutputKey,OutputValue,Description]' \
		--output table \
		$(AWS_OPTS)

resources: ## List all stack resources
	@echo "$(COLOR_BLUE)Stack Resources: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) describe-stack-resources \
		--stack-name $(STACK_NAME) \
		--query 'StackResources[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]' \
		--output table \
		$(AWS_OPTS)

parameters: ## Show stack parameters
	@echo "$(COLOR_BLUE)Stack Parameters: $(STACK_NAME)$(COLOR_RESET)"
	@$(AWS) describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].Parameters[].[ParameterKey,ParameterValue]' \
		--output table \
		$(AWS_OPTS)

# ==================== Change Sets ====================

change-set: validate ## Create a change set to preview changes
	@echo "$(COLOR_BLUE)Creating change set for: $(STACK_NAME)$(COLOR_RESET)"
	@CHANGE_SET_NAME="changeset-$$(date +%Y%m%d-%H%M%S)"; \
	$(AWS) create-change-set \
		--stack-name $(STACK_NAME) \
		--change-set-name $$CHANGE_SET_NAME \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMETERS_FILE) \
		--capabilities CAPABILITY_IAM \
		$(AWS_OPTS); \
	echo "$(COLOR_GREEN)✓ Change set created: $$CHANGE_SET_NAME$(COLOR_RESET)"; \
	echo "$(COLOR_YELLOW)Waiting for change set to be ready...$(COLOR_RESET)"; \
	$(AWS) wait change-set-create-complete \
		--stack-name $(STACK_NAME) \
		--change-set-name $$CHANGE_SET_NAME \
		$(AWS_OPTS); \
	echo "$(COLOR_BLUE)Change set details:$(COLOR_RESET)"; \
	$(AWS) describe-change-set \
		--stack-name $(STACK_NAME) \
		--change-set-name $$CHANGE_SET_NAME \
		--query 'Changes[].[Type,ResourceChange.Action,ResourceChange.LogicalResourceId,ResourceChange.ResourceType,ResourceChange.Replacement]' \
		--output table \
		$(AWS_OPTS)

# ==================== Utility Commands ====================

wait-complete: ## Wait for stack operation to complete
	@echo "$(COLOR_YELLOW)Waiting for stack operation to complete...$(COLOR_RESET)"
	@STACK_STATUS=$$($(AWS) describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].StackStatus' --output text $(AWS_OPTS)); \
	if echo "$$STACK_STATUS" | grep -q "IN_PROGRESS"; then \
		if echo "$$STACK_STATUS" | grep -q "CREATE"; then \
			$(AWS) wait stack-create-complete --stack-name $(STACK_NAME) $(AWS_OPTS); \
		elif echo "$$STACK_STATUS" | grep -q "UPDATE"; then \
			$(AWS) wait stack-update-complete --stack-name $(STACK_NAME) $(AWS_OPTS); \
		fi; \
		echo "$(COLOR_GREEN)✓ Stack operation completed$(COLOR_RESET)"; \
		$(MAKE) status; \
	else \
		echo "$(COLOR_YELLOW)Stack is not in progress state: $$STACK_STATUS$(COLOR_RESET)"; \
	fi

wait-delete: ## Wait for stack deletion to complete
	@echo "$(COLOR_YELLOW)Waiting for stack deletion to complete...$(COLOR_RESET)"
	@$(AWS) wait stack-delete-complete \
		--stack-name $(STACK_NAME) \
		$(AWS_OPTS)
	@echo "$(COLOR_GREEN)✓ Stack deleted successfully$(COLOR_RESET)"

list-stacks: ## List all CloudFormation stacks in the region
	@echo "$(COLOR_BLUE)CloudFormation Stacks in $(REGION):$(COLOR_RESET)"
	@$(AWS) list-stacks \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--query 'StackSummaries[].[StackName,StackStatus,CreationTime]' \
		--output table \
		$(AWS_OPTS)

estimate-cost: validate ## Estimate stack cost (opens AWS Cost Calculator)
	@echo "$(COLOR_BLUE)Generating cost estimate URL...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Note: Cost estimation requires manual review in AWS Console$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Visit: https://calculator.aws/#/$(COLOR_RESET)"

clean: ## Remove temporary files
	@echo "$(COLOR_BLUE)Cleaning temporary files...$(COLOR_RESET)"
	@rm -f .stack-outputs.json .stack-resources.json
	@echo "$(COLOR_GREEN)✓ Cleanup complete$(COLOR_RESET)"

# ==================== Advanced Operations ====================

tail-events: ## Continuously tail stack events (requires watch command)
	@if command -v watch >/dev/null 2>&1; then \
		watch -n 5 "$(AWS) describe-stack-events --stack-name $(STACK_NAME) --max-items 10 --query 'StackEvents[].[Timestamp,ResourceStatus,LogicalResourceId]' --output table $(AWS_OPTS)"; \
	else \
		echo "$(COLOR_RED)Error: 'watch' command not found$(COLOR_RESET)"; \
		echo "$(COLOR_YELLOW)Install with: brew install watch (macOS) or apt-get install watch (Linux)$(COLOR_RESET)"; \
	fi

get-url: ## Get the Application Load Balancer URL
	@$(AWS) describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
		--output text \
		$(AWS_OPTS)

open-url: ## Open the Application Load Balancer URL in browser
	@URL=$$($(MAKE) -s get-url); \
	if [ -n "$$URL" ]; then \
		echo "$(COLOR_BLUE)Opening: $$URL$(COLOR_RESET)"; \
		open "$$URL" 2>/dev/null || xdg-open "$$URL" 2>/dev/null || echo "$(COLOR_YELLOW)Please open manually: $$URL$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED)Error: Could not retrieve URL$(COLOR_RESET)"; \
	fi

# ==================== Default Target ====================

.DEFAULT_GOAL := help
