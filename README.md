# Central de Limpeza de PDFs — Produção

## 1. Requisitos

- Linux com Docker Engine + Docker Compose Plugin
- 2 vCPU ou mais
- 2 GB RAM ou mais (4 GB recomendado com Stirling-PDF)
- 10 GB livres para sistema/imagens/logs
- Nginx somente se for usar domínio/HTTPS

## 2. Subir a aplicação

```bash
docker compose build
docker compose up -d
```

Verificar:

```bash
docker compose ps
docker compose logs -f limpapdf
```

A aplicação fica publicada apenas em `127.0.0.1:8501` no host, para não expor o Streamlit diretamente.

O Stirling-PDF (conversão para DOCX/ODT) fica disponível em `127.0.0.1:8080`.

## 3. Testar localmente no servidor

```bash
curl http://127.0.0.1:8501/_stcore/health
curl http://127.0.0.1:8080/health
```

Ambos devem retornar `ok`.

## 4. Nginx + HTTPS

Copie `nginx/conf.d/limpapdf.conf.example` para a configuração do Nginx e altere:

```text
pdf.seudominio.com.br
```

para o domínio real.

Depois configure o certificado TLS com o mecanismo de certificados adotado no seu servidor.

## 5. Atualizar a aplicação

```bash
git pull
docker compose build --no-cache
docker compose up -d
```

## 6. Parar/reiniciar

```bash
docker compose restart
docker compose down
```

## 7. Limites

O padrão é 100 MB por upload. Para alterar, edite `MAX_UPLOAD_MB` no `docker-compose.yml` e ajuste também `client_max_body_size` no Nginx.

## 8. Stirling-PDF — Conversão para DOCX/ODT

A partir da versão 2.0, a aplicação suporta exportação do PDF limpo para formatos editáveis:

- **DOCX** (Microsoft Word)
- **ODT** (LibreOffice/OpenDocument)
- **PDF** (apenas limpeza, sem conversão)

### Como usar

1. Na barra lateral, expanda **"Stirling-PDF (Conversão ODT/DOCX)"**
2. Marque **"Ativar conversão via Stirling-PDF"**
3. Configure a URL (padrão: `http://stirling-pdf:8080` no Docker, `http://localhost:8080` local)
4. Opcional: informe a **API Key** se configurada no Stirling-PDF (`SECURITY_CUSTOMGLOBALAPIKEY`)
5. Clique em **"Testar conexão"** para validar
6. Na seção **"Formato de Saída"**, escolha: **PDF (limpo)**, **DOCX (Word)** ou **ODT (LibreOffice)**
7. Processe o PDF normalmente

### Stirling-PDF Standalone

Para rodar apenas o Stirling-PDF em outro host ou rede separada:

```bash
docker compose -f docker-compose.stirling.yml up -d
```

Expõe a porta 8080 em todas as interfaces. Ajuste conforme necessário.

### Variáveis de ambiente do Stirling-PDF

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `STIRLING_PDF_BASE_URL` | `http://localhost:8080` | URL base do Stirling-PDF |
| `STIRLING_PDF_API_KEY` | *(vazio)* | Chave de API global (opcional) |
| `STIRLING_PDF_TIMEOUT` | `300` | Timeout em segundos |
| `STIRLING_PDF_MAX_RETRIES` | `2` | Tentativas de reconexão |
| `STIRLING_PDF_VERIFY_SSL` | `true` | Verificar certificados SSL |

### Requisitos de conversão

- **PDFs digitais** (texto selecionável): conversão de alta qualidade
- **PDFs escaneados/imagens**: execute OCR no Stirling-PDF antes de converter
- **Layouts complexos**: podem necessitar ajustes manuais após conversão

## Observação técnica

O app trabalha sobre os comandos de conteúdo de texto do PDF. PDFs com texto convertido em imagem, conteúdo rasterizado, objetos especiais ou marcas d'água fora do fluxo de texto podem não ser removidos por esses métodos.