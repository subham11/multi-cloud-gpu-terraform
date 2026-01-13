.PHONY: help validate plan test clean format lint

help:
	@echo "Multi-Cloud GPU Terraform - Available Commands"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make validate         - Validate Terraform configuration"
	@echo "  make format           - Format Terraform files"
	@echo "  make lint             - Run static analysis (requires tflint)"
	@echo "  make plan-aws         - Preview AWS deployment"
	@echo "  make plan-azure       - Preview Azure deployment"
	@echo "  make plan-gcp         - Preview GCP deployment"
	@echo ""
	@echo "Local Sandbox:"
	@echo "  make sandbox-up       - Start LocalStack + Azurite"
	@echo "  make sandbox-down     - Stop local services"
	@echo "  make sandbox-logs     - View sandbox logs"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            - Remove Terraform cache and state"
	@echo ""

# Validation targets
validate:
	@echo "Running Terraform validation..."
	@bash tests/terraform_validation.sh

format:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive .

lint:
	@echo "Running TFLint..."
	@tflint --init --chdir . 2>/dev/null || true
	@tflint . --format compact

# Plan targets (test deployments)
plan-aws:
	@echo "Generating AWS deployment plan..."
	@bash tests/terraform_plan_test.sh aws ap-south-1 test-gpu-instance

plan-azure:
	@echo "Generating Azure deployment plan..."
	@bash tests/terraform_plan_test.sh azure southeastasia test-gpu-vm

plan-gcp:
	@echo "Generating GCP deployment plan..."
	@bash tests/terraform_plan_test.sh gcp asia-south1 test-gpu-instance dummy-project

# Local sandbox targets
sandbox-up:
	@echo "Starting local sandbox (LocalStack + Azurite)..."
	@docker-compose -f tests/docker-compose.yml up -d
	@echo ""
	@echo "Sandbox started! Services:"
	@echo "  LocalStack (AWS):  http://localhost:4566"
	@echo "  Azurite (Azure):   http://localhost:10000"
	@echo ""
	@echo "Configure AWS CLI for LocalStack:"
	@echo "  export AWS_ACCESS_KEY_ID=test"
	@echo "  export AWS_SECRET_ACCESS_KEY=test"
	@echo "  export AWS_ENDPOINT_URL=http://localhost:4566"

sandbox-down:
	@echo "Stopping sandbox..."
	@docker-compose -f tests/docker-compose.yml down

sandbox-logs:
	@docker-compose -f tests/docker-compose.yml logs -f

# Cleanup
clean:
	@echo "Cleaning up Terraform files..."
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f *.tfstate*
	@rm -f /tmp/tfplan_*
	@echo "Cleanup complete"

# Run all tests
test: validate format plan-aws plan-azure plan-gcp
	@echo ""
	@echo "✓ All tests passed!"
