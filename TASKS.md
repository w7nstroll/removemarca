# TASKS.md — limpapdf-prod

Comprehensive task breakdown derived from repository analysis.

---

## 🧪 Testing & CI/CD (Critical — none exist today)

### Unit Tests
- [ ] Add `pytest` + `pytest-cov` to `requirements-dev.txt`
- [ ] Test `analisar_raio_x`: empty PDF, PDF with text, PDF with diagonal text, PDF with large fonts
- [ ] Test `limpar_pdf_mestre` each mode: Diagonal, Tamanho, Palavras
- [ ] Test edge cases: malformed PDF, password-protected PDF, PDF with only images
- [ ] Test `texto_com_alvo` case-insensitivity, accent handling, empty targets

### Integration Tests
- [ ] Docker build test (CI): `docker compose build` succeeds
- [ ] Healthcheck test: container responds to `/_stcore/health`
- [ ] Upload limit enforcement: reject > MAX_UPLOAD_MB
- [ ] End-to-end: upload → analyze → clean → download produces valid PDF

### Linting & Type Safety
- [ ] Add `ruff` (lint + format), `mypy`, `pre-commit` to `requirements-dev.txt`
- [ ] Configure `pyproject.toml` with `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]`
- [ ] Run `ruff check .`, `ruff format --check .`, `mypy app/` in CI

### CI Workflow (`.github/workflows/ci.yml`)
- [ ] On push/PR: lint → typecheck → unit tests → docker build
- [ ] Cache pip dependencies
- [ ] Publish Docker image on tag (optional)

---

## 🛠 Development Roadmap

### Code Quality
- [ ] Extract PDF processing logic from `limpapdf.py` into `app/pdf_processor.py` (separation of concerns)
- [ ] Add type hints to all functions (currently partial)
- [ ] Add docstrings to public functions
- [ ] Replace `st.exception(exc)` with user-friendly error messages + logging
- [ ] Add structured logging (`structlog` or stdlib `logging`)

### Features
- [ ] **Batch processing**: upload multiple PDFs, process sequentially, download ZIP
- [ ] **Preview mode**: show before/after page thumbnails (use `pdf2image` + poppler)
- [ ] **Preserve metadata**: copy `/Info` dict, XMP metadata to cleaned PDF
- [ ] **OCR fallback**: detect rasterized pages, offer OCR + re-embed (requires `tesseract`, `pdf2image`)
- [ ] **Custom regex patterns** in "Palavras" mode (currently exact substring)
- [ ] **Undo/redo** in UI for multiple cleaning passes
- [ ] **Dark mode** toggle (Streamlit theme config)

### UX Improvements
- [ ] Progress bar shows current file name during batch
- [ ] Download button disabled until processing complete
- [ ] Tooltips explaining each cleaning mode
- [ ] Sample PDFs in repo for quick testing
- [ ] Keyboard shortcuts (Enter to analyze, Ctrl+Enter to clean)

### Performance
- [ ] Parallel page processing with `concurrent.futures.ProcessPoolExecutor`
- [ ] Stream large PDFs instead of loading fully into memory
- [ ] Cache analysis results keyed by file hash

---

## 🏗 Infrastructure & Operations

### Docker Hardening
- [ ] Pin base image digest: `python:3.12-slim-bookworm@sha256:...`
- [ ] Add `docker-compose.override.yml.example` for local dev overrides
- [ ] Multi-stage build: builder stage → runtime stage (smaller image)
- [ ] Scan image with `trivy` or `grype` in CI

### Nginx / TLS
- [ ] Document Let's Encrypt + certbot setup (standalone or DNS challenge)
- [ ] Add `nginx/conf.d/limpapdf-ssl.conf.example` with TLS config
- [ ] HSTS, secure headers, rate limiting on `/` endpoint
- [ ] OCSP stapling config

### Monitoring & Observability
- [ ] Add Prometheus metrics endpoint (`prometheus-client`): requests, latency, errors, upload size
- [ ] Grafana dashboard template (JSON)
- [ ] Structured JSON logs → Loki / Elasticsearch
- [ ] Healthcheck exposes more detail: version, uptime, memory usage

### Backup & Disaster Recovery
- [ ] Document: no persistent data in container (stateless) — nothing to backup
- [ ] If adding user accounts/sessions later: plan for Redis/DB backup

### Deployment Automation
- [ ] `Makefile` or `justfile` with targets: `build`, `up`, `down`, `logs`, `update`, `shell`
- [ ] Ansible playbook or shell script for server bootstrap (Docker, Nginx, certbot)
- [ ] Blue/green or rolling update strategy for zero-downtime deploys

---

## 📚 Documentation

- [ ] `CONTRIBUTING.md`: dev setup, test commands, PR checklist
- [ ] `ARCHITECTURE.md`: data flow diagrams, cleaning algorithm details
- [ ] `SECURITY.md`: vulnerability reporting, threat model (file upload risks)
- [ ] `CHANGELOG.md`: Keep a Changelog format
- [ ] Update `README.md` with: architecture diagram, FAQ, troubleshooting section

---

## 🔒 Security

- [ ] Add `bandit` to CI for static security analysis
- [ ] Scan dependencies with `pip-audit` or `safety` in CI
- [ ] Content-Security-Policy header in Nginx
- [ ] File type validation beyond extension (magic bytes)
- [ ] Rate limit upload endpoint (Nginx `limit_req_zone`)
- [ ] Sanitize filenames in download (`secure_filename` from `werkzeug`)

---

## 📦 Packaging & Distribution (Optional)

- [ ] Publish to Docker Hub / GHCR with semantic versioning
- [ ] `pyproject.toml` with `[project]` metadata for `pip install limpapdf`
- [ ] CLI entry point: `limpapdf clean input.pdf --mode diagonal -o output.pdf`
- [ ] Homebrew tap / Scoop bucket for CLI distribution

---

## Priority Order (Suggested)

| Priority | Tasks |
|----------|-------|
| **P0** | Unit tests, CI workflow, lint/typecheck, Docker hardening |
| **P1** | Code modularization, type hints, logging, batch processing |
| **P2** | Preview mode, OCR fallback, regex patterns, monitoring |
| **P3** | CLI, packaging, dark mode, undo/redo, backup docs |

---

## Notes

- Repository is intentionally minimal. Add tooling incrementally.
- No database, no auth, no persistent state — keeps ops simple.
- All PDF processing is CPU-bound; consider horizontal scaling (multiple containers behind Nginx) before vertical.