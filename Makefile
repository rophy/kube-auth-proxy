.PHONY: build image test clean e2e-setup e2e e2e-all e2e-teardown help

.DEFAULT_GOAL := help

## Build

build: ## Build Docker image (local dev)
	skaffold build

image: ## Build release image
	./scripts/build-image.sh

clean: ## Clean local build artifacts
	rm -rf bin/

## Test

test: ## Run unit tests
	go test -v ./...

## E2E Tests

e2e-setup: ## Deploy test infrastructure to Kind cluster
	skaffold run -p e2e

e2e: e2e-setup ## Run e2e tests (incluster + sidecar)
	bats test/e2e/proxy_incluster.bats test/e2e/proxy_sidecar.bats

e2e-all: e2e-setup ## Run all e2e tests (requires EXTERNAL_TOKEN_REVIEW_URL)
	bats test/e2e/

e2e-teardown: ## Remove test infrastructure
	skaffold delete -p e2e

## Help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
