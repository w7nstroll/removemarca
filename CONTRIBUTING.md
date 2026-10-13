# Contributing to limpapdf

Thank you for your interest in contributing! This guide will help you get started.

## Development Setup

### Prerequisites
- Docker Engine + Docker Compose Plugin
- Python 3.12+ (for local development without Docker)
- Git

### Quick Start (Docker)
```bash
# Clone and start
git clone <repo-url>
cd limpapdf-prod
make dev
```

### Local Python Development
```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Install dev dependencies
make install

# Run Streamlit directly (with hot reload)
streamlit run app/limpapdf.py --server.runOnSave=true
```

## Running Tests

```bash
# All tests with coverage
make test

# Verbose output
make test-verbose

# Only lint/typecheck/security
make lint typecheck security audit

# Everything (CI locally)
make ci-local
```

## Code Style

We use **Ruff** for linting and formatting:
- Line length: 100 characters
- Single quotes
- Import sorting (isort compatible)

```bash
# Auto-fix linting issues
ruff check --fix .

# Format code
ruff format .
```

Type checking with **mypy** (strict mode):
```bash
mypy app/
```

## Pre-commit Hooks

Hooks run automatically on commit. To run manually:
```bash
pre-commit run --all-files
```

Hooks include:
- Ruff (lint + format)
- MyPy (type checking)
- Bandit (security)
- pip-audit (dependencies)
- Basic file checks (trailing whitespace, YAML/TOML/JSON syntax, merge conflicts, private keys)

## Pull Request Checklist

Before submitting a PR, ensure:
- [ ] All tests pass (`make test`)
- [ ] Linting passes (`make lint`)
- [ ] Type checking passes (`make typecheck`)
- [ ] Security scan passes (`make security`)
- [ ] Dependencies are clean (`make audit`)
- [ ] Code is formatted (`make format-check`)
- [ ] Pre-commit hooks pass (`make pre-commit`)
- [ ] Docker image builds (`make docker-build`)
- [ ] Healthcheck works (`make docker-health`)

## Architecture Overview

See [ARCHITECTURE.md](ARCHITECTURE.md) for details on:
- PDF processing pipeline
- Cleaning algorithms (Diagonal, Tamanho, Palavras)
- Streamlit UI structure
- Data flow

## Adding Features

1. **Create an issue** describing the feature
2. **Fork and branch**: `git checkout -b feature/my-feature`
3. **Write tests first** (TDD preferred)
4. **Implement** with type hints and docstrings
5. **Run full test suite** locally
6. **Submit PR** with clear description

## Reporting Issues

- Use GitHub Issues
- Include: OS, Docker version, steps to reproduce, expected vs actual behavior
- For PDF-specific issues: attach a sample PDF (redacted if sensitive)

## Security

- Report vulnerabilities privately via GitHub Security Advisories
- See [SECURITY.md](SECURITY.md) for our security policy

## License

By contributing, you agree your contributions will be licensed under the project's license (MIT).