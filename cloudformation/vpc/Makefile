# VPC CloudFormation Stack Management
# Variables
STACK_NAME ?= demo-vpc-stack
TEMPLATE_FILE = template.cfn.yaml
PARAMETERS_FILE = parameters.json
TAGS_FILE = tags.json
REGION ?= us-east-1

.PHONY: help validate test deploy update delete clean status

help: ## Show this help message
	@echo "VPC CloudFormation Template Management"
	@echo "======================================"
	@echo "This Makefile manages a VPC CloudFormation stack with configurable subnets,"
	@echo "NAT gateways, S3 endpoints, and IPAM support."
	@echo ""
	@echo "Usage: make [target] [STACK_NAME=name] [REGION=region]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  STACK_NAME   CloudFormation stack name (default: $(STACK_NAME))"
	@echo "  REGION       AWS region (default: $(REGION))"

validate: ## Validate CloudFormation template syntax
	@echo "Validating template..."
	aws cloudformation validate-template --template-body file://$(TEMPLATE_FILE) --region $(REGION)

test: validate ## Run template validation and parameter checks
	@echo "Testing template with parameters..."
	aws cloudformation validate-template --template-body file://$(TEMPLATE_FILE) --region $(REGION) > /dev/null
	@if [ -f $(PARAMETERS_FILE) ]; then \
		echo "Parameters file found: $(PARAMETERS_FILE)"; \
	else \
		echo "Warning: Parameters file not found: $(PARAMETERS_FILE)"; \
	fi
	@if [ -f $(TAGS_FILE) ]; then \
		echo "Tags file found: $(TAGS_FILE)"; \
	else \
		echo "Warning: Tags file not found: $(TAGS_FILE)"; \
	fi

deploy: test ## Deploy CloudFormation stack
	@echo "Deploying stack: $(STACK_NAME)"
	aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--parameter-overrides file://$(PARAMETERS_FILE) \
		--tags file://$(TAGS_FILE) \
		--region $(REGION) \
		--capabilities CAPABILITY_IAM

update: test ## Update existing CloudFormation stack
	@echo "Updating stack: $(STACK_NAME)"
	aws cloudformation deploy \
		--template-file $(TEMPLATE_FILE) \
		--stack-name $(STACK_NAME) \
		--parameter-overrides file://$(PARAMETERS_FILE) \
		--tags file://$(TAGS_FILE) \
		--region $(REGION) \
		--capabilities CAPABILITY_IAM

status: ## Show stack status and outputs
	@echo "Stack status for: $(STACK_NAME)"
	aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--query 'Stacks[0].{Status:StackStatus,Created:CreationTime,Updated:LastUpdatedTime}' \
		--output table
	@echo ""
	@echo "Stack outputs:"
	aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(REGION) \
		--query 'Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}' \
		--output table 2>/dev/null || echo "No outputs available"

delete: ## Delete CloudFormation stack
	@echo "Deleting stack: $(STACK_NAME)"
	@printf "Are you sure you want to delete stack $(STACK_NAME)? [y/N]: "; \
	read answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(REGION); \
		echo "Stack deletion initiated. Use 'make status' to monitor progress."; \
	else \
		echo "Stack deletion cancelled."; \
	fi

clean: ## Remove generated files (does not delete stack)
	@echo "Cleaning up generated files..."
	rm -f .aws-sam/build.toml
	rm -rf .aws-sam/
	@echo "Clean complete"
