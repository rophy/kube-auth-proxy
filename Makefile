.PHONY: test test-e2e help

.DEFAULT_GOAL := help

## Test

test: ## Run unit tests
	go test -v ./...

## E2E Tests

test-e2e: ## Run e2e tests
	skaffold run
	bats test/e2e/proxy_sidecar.bats

## Help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
