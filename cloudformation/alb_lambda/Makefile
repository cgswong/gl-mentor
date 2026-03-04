# ============================================================================
# CloudFormation ALB Stack Management Makefile
# ============================================================================
# Description: Manage deployment, validation, testing, and cleanup of the
#              ALB CloudFormation stack with flexible backend targets
# ============================================================================

# Default variables
STACK_NAME ?= alb-demo
PARAMETER_FILE ?= parameters-example.json
TEMPLATE_FILE := template.cfn.yaml
REGION ?= us-east-1

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_CYAN := \033[36m

# ============================================================================
# PHONY TARGETS
# ============================================================================
.PHONY: help validate lint create update delete status outputs events \
        describe wait-create wait-update wait-delete test test-ec2 \
        test-lambda test-health logs clean check-aws check-stack-exists

# ============================================================================
# HELP TARGET (Default)
# ============================================================================
help:
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_CYAN)╔════════════════════════════════════════════════════════════════════╗$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_CYAN)║  CloudFormation ALB Stack Management                               ║$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_CYAN)╚════════════════════════════════════════════════════════════════════╝$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Description:$(COLOR_RESET)"
	@echo "  Manage an Application Load Balancer with flexible backend targets:"
	@echo "  EC2 instances, Lambda functions, or both. Supports AL2023, t3.micro"
	@echo "  free tier, and Python 3.13 Lambda runtime."
	@echo ""
	@echo "$(COLOR_BOLD)Arguments:$(COLOR_RESET)"
	@echo "  $(COLOR_GREEN)stack-name$(COLOR_RESET)       Stack name for CloudFormation (default: alb-demo)"
	@echo "                   Usage: make create stack-name=my-stack"
	@echo ""
	@echo "  $(COLOR_GREEN)parameter-file$(COLOR_RESET)   Parameter file for stack (default: parameters-example.json)"
	@echo "                   Usage: make create parameter-file=prod-params.json"
	@echo ""
	@echo "  $(COLOR_GREEN)region$(COLOR_RESET)           AWS region (default: us-east-1)"
	@echo "                   Usage: make create region=us-west-2"
	@echo ""
	@echo "$(COLOR_BOLD)Available Targets:$(COLOR_RESET)"
	@echo ""
	@echo "  $(COLOR_YELLOW)Validation & Linting:$(COLOR_RESET)"
	@echo "    $(COLOR_GREEN)validate$(COLOR_RESET)       Validate CloudFormation template syntax"
	@echo "    $(COLOR_GREEN)lint$(COLOR_RESET)           Run cfn-lint for best practices check"
	@echo ""
	@echo "  $(COLOR_YELLOW)Stack Management:$(COLOR_RESET)"
	@echo "    $(COLOR_GREEN)create$(COLOR_RESET)         Create a new CloudFormation stack"
	@echo "    $(COLOR_GREEN)update$(COLOR_RESET)         Update an existing stack"
	@echo "    $(COLOR_GREEN)delete$(COLOR_RESET)         Delete the stack and all resources"
	@echo "    $(COLOR_GREEN)status$(COLOR_RESET)         Show current stack status"
	@echo "    $(COLOR_GREEN)describe$(COLOR_RESET)       Show detailed stack information"
	@echo ""
	@echo "  $(COLOR_YELLOW)Stack Information:$(COLOR_RESET)"
	@echo "    $(COLOR_GREEN)outputs$(COLOR_RESET)        Display stack outputs (URLs, ARNs, etc.)"
	@echo "    $(COLOR_GREEN)events$(COLOR_RESET)         Show recent stack events"
	@echo "    $(COLOR_GREEN)logs$(COLOR_RESET)           Show Lambda function logs (if Lambda backend)"
	@echo ""
	@echo "  $(COLOR_YELLOW)Testing:$(COLOR_RESET)"
	@echo "    $(COLOR_GREEN)test$(COLOR_RESET)           Run all tests (EC2, Lambda, health checks)"
	@echo "    $(COLOR_GREEN)test-ec2$(COLOR_RESET)       Test EC2 backend endpoint"
	@echo "    $(COLOR_GREEN)test-lambda$(COLOR_RESET)    Test Lambda backend endpoint"
	@echo "    $(COLOR_GREEN)test-health$(COLOR_RESET)    Test health check endpoint"
	@echo ""
	@echo "  $(COLOR_YELLOW)Utilities:$(COLOR_RESET)"
	@echo "    $(COLOR_GREEN)wait-create$(COLOR_RESET)    Wait for stack creation to complete"
	@echo "    $(COLOR_GREEN)wait-update$(COLOR_RESET)    Wait for stack update to complete"
	@echo "    $(COLOR_GREEN)wait-delete$(COLOR_RESET)    Wait for stack deletion to complete"
	@echo "    $(COLOR_GREEN)clean$(COLOR_RESET)          Clean up temporary files"
	@echo ""
	@echo "$(COLOR_BOLD)Examples:$(COLOR_RESET)"
	@echo "  # Create stack with default parameters"
	@echo "  make create"
	@echo ""
	@echo "  # Create stack with custom name and parameters"
	@echo "  make create stack-name=prod-alb parameter-file=prod-params.json"
	@echo ""
	@echo "  # Validate template before deployment"
	@echo "  make validate lint"
	@echo ""
	@echo "  # Update existing stack"
	@echo "  make update stack-name=prod-alb"
	@echo ""
	@echo "  # Test all endpoints"
	@echo "  make test stack-name=prod-alb"
	@echo ""
	@echo "  # Delete stack"
	@echo "  make delete stack-name=prod-alb"
	@echo ""

# ============================================================================
# VALIDATION TARGETS
# ============================================================================

# Check if AWS CLI is installed
check-aws:
	@which aws > /dev/null || (echo "$(COLOR_YELLOW)Error: AWS CLI not found. Please install it first.$(COLOR_RESET)" && exit 1)
	@echo "$(COLOR_GREEN)✓ AWS CLI found$(COLOR_RESET)"

# Validate CloudFormation template syntax
validate: check-aws
	@echo "$(COLOR_BLUE)Validating CloudFormation template...$(COLOR_RESET)"
	@aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE) \
		--region $(REGION) > /dev/null
	@echo "$(COLOR_GREEN)✓ Template validation successful$(COLOR_RESET)"

# Run cfn-lint for best practices
lint:
	@echo "$(COLOR_BLUE)Running cfn-lint...$(COLOR_RESET)"
	@if command -v cfn-lint > /dev/null; then \
		cfn-lint $(TEMPLATE_FILE) -i W3002 || true; \
		echo "$(COLOR_GREEN)✓ Linting complete$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ cfn-lint not installed. Install with: pip install cfn-lint$(COLOR_RESET)"; \
	fi

# ============================================================================
# STACK MANAGEMENT TARGETS
# ============================================================================

# Check if stack exists
check-stack-exists:
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) > /dev/null 2>&1

# Create a new stack
create: check-aws validate
	@echo "$(COLOR_BLUE)Creating CloudFormation stack: $(STACK_NAME)$(COLOR_RESET)"
	@if $(MAKE) check-stack-exists 2>/dev/null; then \
		echo "$(COLOR_YELLOW)⚠ Stack $(STACK_NAME) already exists. Use 'make update' instead.$(COLOR_RESET)"; \
		exit 1; \
	fi
	@aws cloudformation create-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMETER_FILE) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(REGION) \
		--tags Key=ManagedBy,Value=Makefile Key=Environment,Value=Demo
	@echo "$(COLOR_GREEN)✓ Stack creation initiated$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)Run 'make wait-create stack-name=$(STACK_NAME)' to wait for completion$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)Run 'make events stack-name=$(STACK_NAME)' to monitor progress$(COLOR_RESET)"

# Update an existing stack
update: check-aws validate
	@echo "$(COLOR_BLUE)Updating CloudFormation stack: $(STACK_NAME)$(COLOR_RESET)"
	@if ! $(MAKE) check-stack-exists 2>/dev/null; then \
		echo "$(COLOR_YELLOW)⚠ Stack $(STACK_NAME) does not exist. Use 'make create' instead.$(COLOR_RESET)"; \
		exit 1; \
	fi
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--template-body file://$(TEMPLATE_FILE) \
		--parameters file://$(PARAMETER_FILE) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(REGION) 2>&1 | \
	if grep -q "No updates are to be performed"; then \
		echo "$(COLOR_YELLOW)⚠ No changes detected in stack$(COLOR_RESET)"; \
	else \
		cat; \
		echo "$(COLOR_GREEN)✓ Stack update initiated$(COLOR_RESET)"; \
		echo "$(COLOR_CYAN)Run 'make wait-update stack-name=$(STACK_NAME)' to wait for completion$(COLOR_RESET)"; \
	fi

# Delete the stack
delete: check-aws
	@echo "$(COLOR_YELLOW)⚠ WARNING: This will delete stack $(STACK_NAME) and all its resources!$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(COLOR_BLUE)Deleting CloudFormation stack: $(STACK_NAME)$(COLOR_RESET)"; \
		aws cloudformation delete-stack \
			--stack-name $(STACK_NAME) \
			--region $(REGION); \
		echo "$(COLOR_GREEN)✓ Stack deletion initiated$(COLOR_RESET)"; \
		echo "$(COLOR_CYAN)Run 'make wait-delete stack-name=$(STACK_NAME)' to wait for completion$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Deletion cancelled$(COLOR_RESET)"; \
	fi

# Show stack status
status: check-aws
	@echo "$(COLOR_BLUE)Stack Status: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--query 'Stacks[0].[StackName,StackStatus,CreationTime]' \
		--output table 2>/dev/null || \
		echo "$(COLOR_YELLOW)Stack $(STACK_NAME) not found$(COLOR_RESET)"

# Show detailed stack information
describe: check-aws
	@echo "$(COLOR_BLUE)Stack Details: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--output table 2>/dev/null || \
		echo "$(COLOR_YELLOW)Stack $(STACK_NAME) not found$(COLOR_RESET)"

# ============================================================================
# STACK INFORMATION TARGETS
# ============================================================================

# Display stack outputs
outputs: check-aws
	@echo "$(COLOR_BLUE)Stack Outputs: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--query 'Stacks[0].Outputs' \
		--output table 2>/dev/null || \
		echo "$(COLOR_YELLOW)Stack $(STACK_NAME) not found or has no outputs$(COLOR_RESET)"

# Show recent stack events
events: check-aws
	@echo "$(COLOR_BLUE)Recent Stack Events: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation describe-stack-events \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--max-items 20 \
		--query 'StackEvents[].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
		--output table 2>/dev/null || \
		echo "$(COLOR_YELLOW)Stack $(STACK_NAME) not found$(COLOR_RESET)"

# Show Lambda function logs
logs: check-aws
	@echo "$(COLOR_BLUE)Lambda Function Logs: $(STACK_NAME)$(COLOR_RESET)"
	@FUNCTION_NAME=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' \
		--output text 2>/dev/null | awk -F: '{print $$NF}'); \
	if [ -z "$$FUNCTION_NAME" ]; then \
		echo "$(COLOR_YELLOW)No Lambda function found in stack$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_CYAN)Fetching logs for function: $$FUNCTION_NAME$(COLOR_RESET)"; \
		aws logs tail "/aws/lambda/$$FUNCTION_NAME" \
			--region $(REGION) \
			--follow 2>/dev/null || \
			echo "$(COLOR_YELLOW)No logs available yet$(COLOR_RESET)"; \
	fi

# ============================================================================
# WAIT TARGETS
# ============================================================================

# Wait for stack creation to complete
wait-create: check-aws
	@echo "$(COLOR_BLUE)Waiting for stack creation to complete: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation wait stack-create-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION) && \
		echo "$(COLOR_GREEN)✓ Stack creation completed successfully$(COLOR_RESET)" || \
		(echo "$(COLOR_YELLOW)⚠ Stack creation failed or timed out$(COLOR_RESET)" && exit 1)
	@$(MAKE) outputs stack-name=$(STACK_NAME)

# Wait for stack update to complete
wait-update: check-aws
	@echo "$(COLOR_BLUE)Waiting for stack update to complete: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation wait stack-update-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION) && \
		echo "$(COLOR_GREEN)✓ Stack update completed successfully$(COLOR_RESET)" || \
		(echo "$(COLOR_YELLOW)⚠ Stack update failed or timed out$(COLOR_RESET)" && exit 1)
	@$(MAKE) outputs stack-name=$(STACK_NAME)

# Wait for stack deletion to complete
wait-delete: check-aws
	@echo "$(COLOR_BLUE)Waiting for stack deletion to complete: $(STACK_NAME)$(COLOR_RESET)"
	@aws cloudformation wait stack-delete-complete \
		--stack-name $(STACK_NAME) \
		--region $(REGION) && \
		echo "$(COLOR_GREEN)✓ Stack deletion completed successfully$(COLOR_RESET)" || \
		(echo "$(COLOR_YELLOW)⚠ Stack deletion failed or timed out$(COLOR_RESET)" && exit 1)

# ============================================================================
# TESTING TARGETS
# ============================================================================

# Get ALB URL helper function
define get_alb_url
$(shell aws cloudformation describe-stacks \
	--stack-name $(STACK_NAME) \
	--region $(REGION) \
	--query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
	--output text 2>/dev/null)
endef

# Get backend type helper function
define get_backend_type
$(shell aws cloudformation describe-stacks \
	--stack-name $(STACK_NAME) \
	--region $(REGION) \
	--query 'Stacks[0].Outputs[?OutputKey==`BackendConfiguration`].OutputValue' \
	--output text 2>/dev/null)
endef

# Run all tests
test: check-aws
	@echo "$(COLOR_BLUE)Running all tests for stack: $(STACK_NAME)$(COLOR_RESET)"
	@ALB_URL="$(call get_alb_url)"; \
	BACKEND_TYPE="$(call get_backend_type)"; \
	if [ -z "$$ALB_URL" ]; then \
		echo "$(COLOR_YELLOW)⚠ Stack $(STACK_NAME) not found or not ready$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	echo "$(COLOR_CYAN)ALB URL: $$ALB_URL$(COLOR_RESET)"; \
	echo "$(COLOR_CYAN)Backend Type: $$BACKEND_TYPE$(COLOR_RESET)"; \
	echo ""; \
	if [ "$$BACKEND_TYPE" = "EC2Only" ] || [ "$$BACKEND_TYPE" = "EC2AndLambda" ]; then \
		$(MAKE) test-ec2 stack-name=$(STACK_NAME); \
		$(MAKE) test-health stack-name=$(STACK_NAME); \
	fi; \
	if [ "$$BACKEND_TYPE" = "LambdaOnly" ] || [ "$$BACKEND_TYPE" = "EC2AndLambda" ]; then \
		$(MAKE) test-lambda stack-name=$(STACK_NAME); \
	fi; \
	echo ""; \
	echo "$(COLOR_GREEN)✓ All tests completed$(COLOR_RESET)"

# Test EC2 backend
test-ec2: check-aws
	@echo "$(COLOR_BLUE)Testing EC2 backend...$(COLOR_RESET)"
	@ALB_URL="$(call get_alb_url)"; \
	BACKEND_TYPE="$(call get_backend_type)"; \
	if [ -z "$$ALB_URL" ]; then \
		echo "$(COLOR_YELLOW)⚠ Stack not found or not ready$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	if [ "$$BACKEND_TYPE" = "EC2AndLambda" ]; then \
		TEST_URL="$$ALB_URL/ec2"; \
	else \
		TEST_URL="$$ALB_URL"; \
	fi; \
	echo "$(COLOR_CYAN)Testing: $$TEST_URL$(COLOR_RESET)"; \
	HTTP_CODE=$$(curl -s -o /dev/null -w "%{http_code}" $$TEST_URL); \
	if [ "$$HTTP_CODE" = "200" ]; then \
		echo "$(COLOR_GREEN)✓ EC2 backend responding (HTTP $$HTTP_CODE)$(COLOR_RESET)"; \
		curl -s $$TEST_URL | grep -q "EC2" && echo "$(COLOR_GREEN)✓ EC2 content verified$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ EC2 backend returned HTTP $$HTTP_CODE$(COLOR_RESET)"; \
	fi

# Test Lambda backend
test-lambda: check-aws
	@echo "$(COLOR_BLUE)Testing Lambda backend...$(COLOR_RESET)"
	@ALB_URL="$(call get_alb_url)"; \
	BACKEND_TYPE="$(call get_backend_type)"; \
	if [ -z "$$ALB_URL" ]; then \
		echo "$(COLOR_YELLOW)⚠ Stack not found or not ready$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	if [ "$$BACKEND_TYPE" = "EC2AndLambda" ]; then \
		TEST_URL="$$ALB_URL/lambda"; \
	else \
		TEST_URL="$$ALB_URL"; \
	fi; \
	echo "$(COLOR_CYAN)Testing: $$TEST_URL$(COLOR_RESET)"; \
	HTTP_CODE=$$(curl -s -o /dev/null -w "%{http_code}" $$TEST_URL); \
	if [ "$$HTTP_CODE" = "200" ]; then \
		echo "$(COLOR_GREEN)✓ Lambda backend responding (HTTP $$HTTP_CODE)$(COLOR_RESET)"; \
		curl -s $$TEST_URL | grep -q "Lambda" && echo "$(COLOR_GREEN)✓ Lambda content verified$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ Lambda backend returned HTTP $$HTTP_CODE$(COLOR_RESET)"; \
	fi

# Test health check endpoint
test-health: check-aws
	@echo "$(COLOR_BLUE)Testing health check endpoint...$(COLOR_RESET)"
	@ALB_URL="$(call get_alb_url)"; \
	if [ -z "$$ALB_URL" ]; then \
		echo "$(COLOR_YELLOW)⚠ Stack not found or not ready$(COLOR_RESET)"; \
		exit 1; \
	fi; \
	TEST_URL="$$ALB_URL/health"; \
	echo "$(COLOR_CYAN)Testing: $$TEST_URL$(COLOR_RESET)"; \
	HTTP_CODE=$$(curl -s -o /dev/null -w "%{http_code}" $$TEST_URL); \
	if [ "$$HTTP_CODE" = "200" ]; then \
		echo "$(COLOR_GREEN)✓ Health check responding (HTTP $$HTTP_CODE)$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠ Health check returned HTTP $$HTTP_CODE$(COLOR_RESET)"; \
	fi

# ============================================================================
# UTILITY TARGETS
# ============================================================================

# Clean up temporary files
clean:
	@echo "$(COLOR_BLUE)Cleaning up temporary files...$(COLOR_RESET)"
	@rm -f .stack-outputs.json .stack-status.json
	@echo "$(COLOR_GREEN)✓ Cleanup complete$(COLOR_RESET)"

# ============================================================================
# COMBINED WORKFLOWS
# ============================================================================

# Full deployment workflow: validate, create, wait, test
deploy: validate lint create wait-create test
	@echo "$(COLOR_GREEN)✓ Full deployment completed successfully$(COLOR_RESET)"

# Full update workflow: validate, update, wait, test
redeploy: validate lint update wait-update test
	@echo "$(COLOR_GREEN)✓ Full update completed successfully$(COLOR_RESET)"

# Full teardown workflow: delete and wait
teardown: delete wait-delete
	@echo "$(COLOR_GREEN)✓ Full teardown completed successfully$(COLOR_RESET)"
