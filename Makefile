.DEFAULT_GOAL := help
SHELL         := /bin/bash
.SHELLFLAGS   := -euo pipefail -c

# ── Colours ───────────────────────────────────────────────────────────────────
BOLD  := $(shell tput -T xterm bold 2>/dev/null || echo '')
RESET := $(shell tput -T xterm sgr0  2>/dev/null || echo '')
GREEN := $(shell tput -T xterm setaf 2 2>/dev/null || echo '')
CYAN  := $(shell tput -T xterm setaf 6 2>/dev/null || echo '')

# ── Variables ─────────────────────────────────────────────────────────────────
TERRAFORM_DIR  := terraform
HELM_DIR       := helm/charts
ARGOCD_DIR     := argocd
KUBERNETES_DIR := kubernetes

# ── Help ──────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help message
	@echo ''
	@echo '$(BOLD)Enterprise Multi-Region Kubernetes Platform$(RESET)'
	@echo ''
	@echo '$(CYAN)Usage:$(RESET)'
	@echo '  make $(GREEN)<target>$(RESET)'
	@echo ''
	@echo '$(CYAN)Targets:$(RESET)'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_\/%-]+:.*##/ { printf "  $(GREEN)%-30s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ''

# ── Developer Tooling ─────────────────────────────────────────────────────────
.PHONY: install-tools
install-tools: ## Install all required CLI tools (macOS via Homebrew)
	@echo "$(CYAN)Installing platform tools...$(RESET)"
	brew install terraform kubectl helm argocd awscli pre-commit tflint checkov \
	             kubeconform shellcheck markdownlint-cli terraform-docs
	@echo "$(GREEN)Tools installed.$(RESET)"

.PHONY: hooks
hooks: ## Install and update pre-commit hooks
	@echo "$(CYAN)Installing pre-commit hooks...$(RESET)"
	pre-commit install --hook-type pre-commit
	pre-commit install --hook-type commit-msg
	pre-commit autoupdate
	@echo "$(GREEN)Hooks installed.$(RESET)"

# ── Validation ────────────────────────────────────────────────────────────────
.PHONY: validate
validate: validate-terraform validate-helm validate-kubernetes validate-shell ## Run all validators

.PHONY: validate-terraform
validate-terraform: ## Validate all Terraform configurations
	@echo "$(CYAN)Validating Terraform...$(RESET)"
	@find $(TERRAFORM_DIR) -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		echo "  → $$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -no-color > /dev/null 2>&1 || true; \
		terraform -chdir="$$dir" validate -no-color; \
	done
	@echo "$(GREEN)Terraform validation passed.$(RESET)"

.PHONY: validate-helm
validate-helm: ## Lint all Helm charts
	@echo "$(CYAN)Linting Helm charts...$(RESET)"
	@find $(HELM_DIR) -name "Chart.yaml" -exec dirname {} \; | sort -u | while read chart; do \
		echo "  → $$chart"; \
		helm lint "$$chart"; \
	done
	@echo "$(GREEN)Helm lint passed.$(RESET)"

.PHONY: validate-kubernetes
validate-kubernetes: ## Validate Kubernetes manifests with kubeconform
	@echo "$(CYAN)Validating Kubernetes manifests...$(RESET)"
	@find $(KUBERNETES_DIR) -name "*.yaml" -o -name "*.yml" | \
		kubeconform -kubernetes-version 1.29.0 -strict -summary
	@echo "$(GREEN)Kubernetes manifest validation passed.$(RESET)"

.PHONY: validate-shell
validate-shell: ## Lint shell scripts with shellcheck
	@echo "$(CYAN)Linting shell scripts...$(RESET)"
	@find scripts/ -name "*.sh" | xargs -r shellcheck --severity=warning
	@echo "$(GREEN)Shell lint passed.$(RESET)"

# ── Formatting ────────────────────────────────────────────────────────────────
.PHONY: fmt
fmt: fmt-terraform ## Format all code

.PHONY: fmt-terraform
fmt-terraform: ## Format Terraform files
	@echo "$(CYAN)Formatting Terraform...$(RESET)"
	terraform fmt -recursive $(TERRAFORM_DIR)
	@echo "$(GREEN)Terraform formatted.$(RESET)"

# ── Security ──────────────────────────────────────────────────────────────────
.PHONY: security-scan
security-scan: ## Run security scans (checkov, gitleaks)
	@echo "$(CYAN)Running security scans...$(RESET)"
	checkov -d $(TERRAFORM_DIR) --framework terraform --quiet
	gitleaks detect --source . --verbose
	@echo "$(GREEN)Security scan complete.$(RESET)"

.PHONY: tflint
tflint: ## Run tflint on all Terraform modules
	@echo "$(CYAN)Running tflint...$(RESET)"
	@find $(TERRAFORM_DIR) -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		echo "  → $$dir"; \
		tflint --chdir="$$dir" --config="$(CURDIR)/.tflint.hcl"; \
	done
	@echo "$(GREEN)tflint passed.$(RESET)"

# ── Docs ──────────────────────────────────────────────────────────────────────
.PHONY: docs
docs: ## Regenerate Terraform module documentation
	@echo "$(CYAN)Generating Terraform docs...$(RESET)"
	@find $(TERRAFORM_DIR)/modules -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do \
		echo "  → $$dir"; \
		terraform-docs markdown table --output-file README.md --output-mode inject "$$dir"; \
	done
	@echo "$(GREEN)Documentation updated.$(RESET)"

# ── Pre-commit ────────────────────────────────────────────────────────────────
.PHONY: pre-commit
pre-commit: ## Run all pre-commit hooks against all files
	pre-commit run --all-files

# ── Clean ─────────────────────────────────────────────────────────────────────
.PHONY: clean
clean: ## Remove local generated files
	@echo "$(CYAN)Cleaning up...$(RESET)"
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Clean complete.$(RESET)"
