# Makefile for limpapdf development
# Usage: make <target>

.PHONY: help install test lint typecheck format security docker-build docker-up docker-down docker-logs docker-shell clean

# Default target
help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install development dependencies
	pip install -r requirements-dev.txt
	pre-commit install

test: ## Run unit tests with coverage
	pytest --cov=app --cov-report=term-missing

test-verbose: ## Run tests with verbose output
	pytest -v --cov=app --cov-report=term-missing

lint: ## Run ruff linter
	ruff check .

format: ## Format code with ruff
	ruff format .

format-check: ## Check formatting without changes
	ruff format --check .

typecheck: ## Run mypy type checker
	mypy app/

security: ## Run bandit security linter
	bandit -r app/

audit: ## Audit dependencies for vulnerabilities
	pip-audit -r requirements.txt -r requirements-dev.txt

pre-commit: ## Run all pre-commit hooks
	pre-commit run --all-files

docker-build: ## Build Docker image
	docker compose build

docker-build-nocache: ## Build Docker image without cache
	docker compose build --no-cache

docker-up: ## Start services in background
	docker compose up -d

docker-down: ## Stop and remove services
	docker compose down

docker-down-v: ## Stop and remove services with volumes
	docker compose down -v

docker-restart: ## Restart services
	docker compose restart

docker-logs: ## Follow service logs
	docker compose logs -f limpapdf

docker-ps: ## Show service status
	docker compose ps

docker-shell: ## Open shell in running container
	docker compose exec limpapdf bash

docker-health: ## Check health endpoint
	curl -f http://127.0.0.1:8501/_stcore/health

docker-update: ## Pull latest, rebuild, and restart
	git pull
	docker compose build --no-cache
	docker compose up -d

clean: ## Clean up build artifacts and caches
	rm -rf __pycache__ .pytest_cache .coverage coverage.xml htmlcov bandit-report.json audit-report.json
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

ci-local: lint typecheck test security audit ## Run all CI checks locally

# Development workflow
dev: docker-build docker-up docker-logs ## Build, start, and follow logs

# Release
tag: ## Create and push a version tag (usage: make tag VERSION=v0.1.0)
	@if [ -z "$(VERSION)" ]; then echo "Usage: make tag VERSION=v0.1.0"; exit 1; fi
	git tag -a $(VERSION) -m "Release $(VERSION)"
	git push origin $(VERSION)