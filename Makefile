.DEFAULT_GOAL := help

export PYROOT=.
export ANSIBLEROOT=./ansible/
VALIDATION_REPORT=reports/All-Host-Validation-Report.txt

.PHONY: help
help:
		@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
		sort | \
		awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

.PHONY: full-network-lifecycle
full-network-lifecycle: ## Create, compare, deploy and validate data model
		@echo "^-^-^-^-^-^- CREATING DATA MODEL -^-^-^-^-^-^"
		ansible-playbook create-data-model.yml
		@echo "*********************************************"
		@echo "^-^-^-^-^-^- COMPARING DATA MODEL -^-^-^-^-^-^"
		ansible-playbook data-model-compare.yml
		@echo "*********************************************"
		@echo "^-^-^-^-^-^- DEPLOYING DATA MODEL -^-^-^-^-^-^"
		ansible-playbook data-model-deploy.yml
		@echo "*********************************************"
		@echo "^-^-^-^-^-^- VALIDATING DATA MODEL -^-^-^-^-^-^"
		ansible-playbook data-model-validate.yml
		@echo "^-^-^-^-^-^- COMPLIANCE RESULTS -^-^-^-^-^-^"
		cat $(VALIDATION_REPORT)
		@echo "*********************************************"

.PHONY: linting-checks
linting-checks: ## Perform ansible-lint and yamllint on all files.
		yamllint *.yml
		ansible-lint *.yml



