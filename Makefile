.DEFAULT_GOAL := help

export PYROOT=.
export ANSIBLEROOT=./ansible/

.PHONY: help
help:
		@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
		sort | \
		awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

.PHONY: full-network-lifecycle
full-network-lifecycle: ## Create, compare, deploy and validate data model
		ansible-playbook create-data-model.yml
		ansible-playbook data-model-compare.yml
		ansible-playbook data-model-deploy.yml
		ansible-playbook data-model-validate.yml


