.DEFAULT_GOAL := help

export PYROOT=.
export ANSIBLEROOT=./ansible/
VALIDATION_REPORT=reports/All-Host-Validation-Report.txt

.PHONY: help
help:
		@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
		sort | \
		awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

.PHONY: linting-checks
linting-checks: ## Perform ansible-lint and yamllint on all files.
		yamllint *.yml
		ansible-lint *.yml

.PHONY: clean-dir
clean-dir: ## Remove all automatically generated directories caused from playbooks.
		rm -rf configs
		rm -rf validate
		rm -rf reports

.PHONY: plan
plan: ## Create node-friendly data model from your fabric plan.
	ansible-playbook create-data-model.yml

.PHONY: design
design: ## Design the applicable changes to the fabric.
	ansible-playbook data-model-compare.yml

.PHONY: deploy
deploy: ## Deploy the applicable changes to the fabric, based on the design.
	ansible-playbook data-model-deploy.yml

.PHONY: validate
validate: ## Validate the fabric solution.
	ansible-playbook data-model-validate.yml
	cat $(VALIDATION_REPORT)

.PHONY: network-lifecycle
network-lifecycle: plan design deploy validate ## Plan, design, deploy and validate data model (all playbooks).
