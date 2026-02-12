.PHONY: build image test e2e-setup e2e e2e-teardown help

.DEFAULT_GOAL := help

## Build

build: ## Build Docker image (local dev)
	skaffold build

image: ## Build release image
	./scripts/build-image.sh

## Test

test: ## Run unit tests
	go test -v ./...

## E2E Tests

e2e-setup: ## Deploy test infrastructure to Kind cluster
	skaffold run

e2e: e2e-setup ## Run e2e tests
	bats test/e2e/proxy_sidecar.bats

e2e-teardown: ## Remove test infrastructure
	skaffold delete

## Help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
