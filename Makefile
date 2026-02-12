.PHONY: build image test clean help

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

## Help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
