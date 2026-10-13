# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with pytest (unit + integration)
- CI/CD pipeline with GitHub Actions (lint, typecheck, test, security, docker)
- Pre-commit hooks (ruff, mypy, bandit, pip-audit)
- Multi-stage Dockerfile with pinned base image digest
- Nginx SSL/TLS configuration template with security headers
- Development tooling: Makefile, docker-compose.override.yml.example
- Documentation: CONTRIBUTING.md, ARCHITECTURE.md, SECURITY.md, AGENTS.md, TASKS.md
- pyproject.toml with tool configurations (ruff, mypy, pytest, bandit, coverage)

### Changed
- Dockerfile: multi-stage build for smaller image
- .gitignore: added dev artifacts, override files, test outputs
- requirements-dev.txt: separated dev dependencies

### Security
- Container hardening: non-root, no capabilities, no-new-privileges
- Dependency scanning in CI (pip-audit, bandit)
- Pinned base image digest for reproducibility

## [0.1.0] - 2026-10-10

### Added
- Initial release: Streamlit PDF cleaning app
- Three cleaning modes: Diagonal, Tamanho, Palavras
- Raio-X PDF analysis with text extraction
- Docker + Docker Compose deployment
- Nginx reverse proxy configuration (HTTP)
- Upload size limit (MAX_UPLOAD_MB)
- Healthcheck endpoint
- Portuguese UI

---

## Release Template

### [X.Y.Z] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes to existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Removed features

#### Fixed
- Bug fixes

#### Security
- Vulnerability fixes