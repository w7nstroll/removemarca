# Architecture Documentation

## System Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User Browser  │────▶│   Nginx (SSL)    │────▶│  Streamlit App  │
│   (HTTPS)       │     │  :443 → :8501    │     │  (localhost)    │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌──────────────────┐
                                                 │  PDF Processor   │
                                                 │  (pikepdf)       │
                                                 └──────────────────┘
```

## Components

### 1. Streamlit Web UI (`app/limpapdf.py`)
- **Single-page application** with sidebar configuration
- **File uploader** with size limit (`MAX_UPLOAD_MB`)
- **Three cleaning modes** via radio buttons
- **Raio-X analysis** button → stores DataFrame in `st.session_state`
- **Progress bar** during processing
- **Download button** for cleaned PDF

### 2. PDF Processing Core

#### `analisar_raio_x(pdf_bytes) -> pd.DataFrame`
Extracts all text commands from PDF content streams.

**Algorithm:**
1. Open PDF with `pikepdf.Pdf.open(io.BytesIO(pdf_bytes))`
2. For each page, parse content stream: `parse_content_stream(page)`
3. Track graphics state stack (`q`/`Q`), current transformation matrix (`cm`), text matrix (`Tm`), font size (`Tf`)
4. For each `Tj`/`TJ` operator:
   - Compute real font size: `|font_size × √(tm[0]² + tm[1]²)|`
   - Detect diagonal: `|tm[1]| > 0.1` or `|tm[2]| > 0.1` or `|ctm[1]| > 0.1` or `|ctm[2]| > 0.1`
   - Extract text via `extrair_textos_tj()`
   - Filter printable chars, length > 1
5. Return deduplicated DataFrame with columns: `Página`, `Trecho Encontrado`, `Tamanho da Fonte`, `Inclinado?`

#### `limpar_pdf_mestre(pdf_bytes, modo, alvos, limite_tamanho) -> bytes`
Removes text based on selected mode.

**Modes:**

| Mode | Condition | Action |
|------|-----------|--------|
| **Diagonal** | `is_diagonal == True` | Replace text operand with empty string |
| **Tamanho** | `tamanho_real >= limite_tamanho` | Replace text operand with empty string |
| **Palavras** | `texto_com_alvo(texto, alvos) == True` | Replace matching text (TJ: per-item) |

**Processing per page:**
1. Parse content stream
2. Track same graphics state as analysis
3. For each text command, evaluate removal condition
4. If removing:
   - `Tj`: `operandos[0] = pikepdf.String("")`
   - `TJ`: Replace matching `pikepdf.String` items in array with `pikepdf.String("")`
5. Rebuild content stream: `unparse_content_stream(novos_comandos)`
6. Save linearized PDF: `pdf.save(output, linearize=True)`

### 3. Helper Functions

| Function | Purpose |
|----------|---------|
| `limpar_operador(op)` | Normalize operator bytes/str (remove `b'...'`, quotes) |
| `texto_do_operando(op)` | Safe string conversion |
| `extrair_textos_tj(operandos, op)` | Extract text from `Tj` (single) or `TJ` (array) |
| `texto_com_alvo(texto, alvos)` | Case-insensitive substring match |

## Data Flow

```
PDF Upload (bytes)
       │
       ▼
┌──────────────────┐
│ analisar_raio_x  │──▶ DataFrame (stored in session_state)
└──────────────────┘
       │
       ▼ (user clicks "Limpar PDF")
┌──────────────────┐
│ limpar_pdf_mestre│──▶ Cleaned PDF bytes
└──────────────────┘
       │
       ▼
Download Button
```

## Cleaning Algorithm Details

### Diagonal Detection
Uses transformation matrices to detect rotated/sheared text:
- `Tm` (text matrix): `[a, b, c, d, e, f]` where `b, c` are shear
- `CTM` (current transformation matrix): accumulated from `cm` operators
- Threshold: `|b| > 0.1` or `|c| > 0.1` in either matrix

### Font Size Calculation
Real rendered size = `font_size × √(tm[0]² + tm[1]²)`
- `font_size` from `Tf` operator
- `tm[0], tm[1]` from `Tm` operator (scale factors)

### TJ Array Handling
`TJ` takes an array of strings and numbers (kerning adjustments).
- "Palavras" mode: iterates array items, replaces only matching `pikepdf.String` items
- Other modes: replaces entire array with empty strings

## Limitations

1. **Rasterized content**: Text converted to images, scanned pages, watermarks as images — not in text stream
2. **Special PDF objects**: Annotations, form fields, layers (OCG) — not processed
3. **Encrypted PDFs**: Password-protected files raise exceptions
4. **Complex layouts**: Overlapping text, transparency groups — may produce unexpected results
5. **Font subsetting**: Embedded subset fonts — text extraction still works but editing may break rendering

## Docker Architecture

### Multi-stage Build
```
builder stage:     python:3.12-slim + gcc → pip install → /install
runtime stage:     python:3.12-slim → COPY --from=builder /install → app/ → appuser
```

### Runtime Configuration
- **Non-root user**: `appuser` (UID/GID auto-assigned)
- **Security**: `no-new-privileges`, `cap_drop: ALL`
- **Resources**: 2GB RAM, 2 CPU (configurable in compose)
- **Healthcheck**: HTTP GET `/_stcore/health` every 30s
- **Port**: 8501 bound to `127.0.0.1` (host) → not publicly exposed

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_UPLOAD_MB` | 100 | Upload size limit (MB) |
| `TZ` | America/Recife | Container timezone |
| `STREAMLIT_SERVER_HEADLESS` | true | Disable browser auto-open |
| `STREAMLIT_BROWSER_GATHER_USAGE_STATS` | false | Disable telemetry |

## Nginx Reverse Proxy

### HTTP → HTTPS Redirect
- Port 80: redirects to HTTPS, serves ACME challenges

### HTTPS Termination
- TLS 1.2/1.3 only
- Modern cipher suites
- HSTS (after cert validation)
- OCSP Stapling

### Proxy Settings
- WebSocket upgrade headers for Streamlit
- 300s timeout for large PDF processing
- Rate limiting: 10 req/s burst 20
- Security headers: CSP, X-Frame-Options, etc.

### Upload Limit
Must match `MAX_UPLOAD_MB` in docker-compose.yml:
```nginx
client_max_body_size 100M;
```

## Extensibility Points

1. **New cleaning modes**: Add branch in `limpar_pdf_mestre` mode switch
2. **Custom text filters**: Extend `texto_com_alvo` with regex/callable support
3. **Output formats**: Add `pdf.save()` options (encryption, compression)
4. **Batch processing**: Wrap `limpar_pdf_mestre` in loop with progress aggregation
5. **OCR integration**: Detect empty `analisar_raio_x` results → trigger OCR pipeline

## Performance Considerations

- **Memory**: Entire PDF loaded into memory (bytes → pikepdf object)
- **CPU**: Single-threaded page processing
- **Optimization opportunities**:
  - Parallel page processing with `ProcessPoolExecutor`
  - Streaming for large PDFs (>100MB)
  - Caching analysis by file hash (SHA256)