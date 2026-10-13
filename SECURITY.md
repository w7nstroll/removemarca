# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | ✅ |
| Previous release | ⚠️ Security fixes only |

## Reporting a Vulnerability

**Do not open public issues for security vulnerabilities.**

Report privately via **GitHub Security Advisories**:
1. Go to the repository's **Security** tab
2. Click **Report a vulnerability**
3. Fill in details and submit

We aim to:
- Acknowledge within 48 hours
- Provide initial assessment within 7 days
- Release fix within 30 days (depending on severity)

## Threat Model

### Assets
- User-uploaded PDF files (may contain sensitive data)
- Processed PDF output
- Container runtime environment

### Attack Vectors

| Vector | Risk | Mitigation |
|--------|------|------------|
| Malicious PDF (parser exploit) | High | `pikepdf` uses `qpdf` (C++, mature); non-root container; no-new-privileges; cap_drop ALL |
| Large file DoS | Medium | `MAX_UPLOAD_MB` limit (default 100MB); Nginx `client_max_body_size`; Streamlit `max_upload_size` |
| Path traversal in filename | Low | `secure_filename` not yet implemented (TODO); download uses user-supplied name |
| XSS via PDF content | Low | Streamlit escapes by default; CSP headers in Nginx |
| Info disclosure via errors | Low | `st.exception` shows traceback; should be replaced with generic messages (TODO) |
| Dependency vulnerabilities | Medium | `pip-audit` in CI; Dependabot alerts |

### Trust Boundaries

```
Internet ──▶ Nginx (TLS, rate limit, CSP) ──▶ Streamlit (localhost only) ──▶ pikepdf (qpdf)
                                                              │
                                                              ▼
                                                     Container (non-root, no caps)
```

## Security Controls

### Container Hardening
- Non-root user (`appuser`)
- Read-only root filesystem (not yet enabled — TODO)
- No capabilities (`cap_drop: ALL`)
- No new privileges (`no-new-privileges:true`)
- Resource limits (memory, CPU)

### Network
- App binds only to `127.0.0.1:8501`
- Nginx terminates TLS, proxies to localhost
- No outbound network access needed (but not restricted — TODO)

### File Handling
- Upload size enforced at 3 layers: Nginx, Streamlit, application code
- Temporary files in memory (`io.BytesIO`), not disk
- No persistent storage in container

### Dependencies
- Pinned versions in `requirements.txt` (semantic ranges)
- `pip-audit` in CI pipeline
- `bandit` static analysis in CI
- Base image digest pinned in Dockerfile

## Secure Deployment Checklist

- [ ] Use HTTPS (Let's Encrypt or managed certs)
- [ ] Set strong `MAX_UPLOAD_MB` (business requirement)
- [ ] Configure Nginx rate limiting
- [ ] Enable HSTS after cert validation
- [ ] Monitor container logs for anomalies
- [ ] Keep base image updated (rebuild weekly)
- [ ] Enable Dependabot/renovate for dependency updates
- [ ] Scan images with `trivy`/`grype` before deploy

## Known Limitations

1. **No authentication/authorization** — anyone with network access can upload
2. **No audit logging** — upload/process events not logged
3. **No data retention policy** — files processed in memory only, but no guarantees
4. **Error messages may leak internals** — `st.exception` shows full traceback

## Future Improvements

- [ ] Add `secure_filename` for downloads
- [ ] Replace `st.exception` with user-friendly errors + server-side logging
- [ ] Add authentication (OAuth2/OIDC proxy or Streamlit auth)
- [ ] Structured audit logging (JSON → Loki/ELK)
- [ ] Read-only root filesystem in Docker
- [ ] Network policy (egress deny)
- [ ] Content-Disposition: attachment for downloads