# AGENTS.md — limpapdf-prod

## Project Overview
Streamlit web app for PDF text/watermark cleaning using `pikepdf`. Runs in Docker, binds to `127.0.0.1:8501`. Nginx reverse proxy for HTTPS in production.

## Developer Commands
```bash
# Build & start
docker compose build
docker compose up -d

# Verify
docker compose ps
docker compose logs -f limpapdf
curl http://127.0.0.1:8501/_stcore/health  # should return "ok"

# Update
git pull
docker compose build --no-cache
docker compose up -d

# Stop/restart
docker compose restart
docker compose down
```

## Configuration
- **Upload limit**: `MAX_UPLOAD_MB` in `docker-compose.yml` (default 100). Also update `client_max_body_size` in Nginx config.
- **Timezone**: `TZ=America/Recife` in compose.
- **Resources**: 2GB RAM, 2 vCPU limit in compose.

## Architecture
- **Single container**: Python 3.12 slim, runs as non-root `appuser`.
- **Entry point**: `streamlit run app/limpapdf.py --server.address=0.0.0.0 --server.port=8501`
- **Healthcheck**: Hits `/_stcore/health` every 30s.
- **No tests/lint/typecheck** configured. No CI workflows.

## Key Files
- `app/limpapdf.py` — All logic: Streamlit UI, PDF analysis (raio-x), 3 cleaning modes (Diagonal, Tamanho, Palavras).
- `requirements.txt` — `streamlit>=1.40,<2`, `pikepdf>=9,<11`, `pandas>=2.2,<3`
- `nginx/conf.d/limpapdf.conf.example` — Reverse proxy template (update `server_name`, add TLS).

## Cleaning Modes (in `limpar_pdf_mestre`)
1. **Diagonal** — Removes text commands with diagonal transformation matrix (`tm[1]`, `tm[2]`, `ctm[1]`, `ctm[2]` > 0.1).
2. **Tamanho** — Removes text with rendered font size ≥ threshold.
3. **Palavras** — Removes text containing target words (comma/semicolon/newline separated). For `TJ` arrays, replaces matching strings with empty string.

## Gotchas
- **PDFs with rasterized text / images / watermarks outside text stream** — not removable by this tool (stated in README).
- **Port binding**: App only on `127.0.0.1:8501` — not exposed publicly without Nginx.
- **No Python dev environment** — all runs via Docker. No `pytest`, `ruff`, `mypy`, etc.
- **Session state** used for "Raio-X" analysis results (`st.session_state["raio_x"]`).