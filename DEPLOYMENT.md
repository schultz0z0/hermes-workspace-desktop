# Deploy Hermes na VPS

Guia direto para subir e manter o stack Hermes na VPS.

Este projeto sobe:

- Hermes Agent API: `https://api-hermes.solucoes-nexus.tech`
- Hermes Dashboard: `https://hermes.solucoes-nexus.tech`
- Hermes Workspace: `https://workspace.solucoes-nexus.tech`
- Open WebUI: `https://chat.solucoes-nexus.tech`
- Hermes Kanban: dentro do dashboard em `https://hermes.solucoes-nexus.tech`
- SearXNG interno: usado pelo Hermes Agent, sem dominio publico

O Traefik deve rodar em outro compose na mesma VPS, com Docker provider ativo e
`exposedbydefault=false`. Este stack apenas declara labels do Traefik.

## 1. DNS

Crie registros `A` apontando para o IP publico da VPS:

```text
hermes.solucoes-nexus.tech
workspace.solucoes-nexus.tech
api-hermes.solucoes-nexus.tech
chat.solucoes-nexus.tech
```

## 2. Preparar pasta

Na VPS:

```bash
mkdir -p /opt/hermes
cd /opt/hermes
```

Clone o repositorio:

```bash
git clone https://github.com/schultz0z0/hermes-workspace-desktop .
```

Se o projeto ja existir:

```bash
cd /opt/hermes
git pull
```

## 3. Configurar `.env`

Crie o arquivo:

```bash
cp .env.example .env
nano .env
```

Campos obrigatorios:

```env
TZ=America/Sao_Paulo
VPS_IP=92.112.179.235

HERMES_DOMAIN=hermes.solucoes-nexus.tech
WORKSPACE_DOMAIN=workspace.solucoes-nexus.tech
HERMES_API_DOMAIN=api-hermes.solucoes-nexus.tech
CHAT_DOMAIN=chat.solucoes-nexus.tech

API_SERVER_KEY=<chave-forte>
HERMES_PASSWORD=<senha-workspace>
DASHBOARD_BASIC_AUTH=<usuario:hash>

OPENWEBUI_SECRET_KEY=<chave-forte>
OPENWEBUI_ADMIN_NAME=NexusAI
OPENWEBUI_ADMIN_EMAIL=raphaelschultz12@gmail.com
OPENWEBUI_ADMIN_PASSWORD=<senha-openwebui>

SEARXNG_SECRET=<chave-forte>
```

Nao usamos `TRAEFIK_HOST` neste stack. Cada servico tem um dominio explicito:
`HERMES_DOMAIN`, `WORKSPACE_DOMAIN`, `HERMES_API_DOMAIN` e `CHAT_DOMAIN`.

Gerar chaves fortes:

```bash
openssl rand -hex 32
```

Gerar Basic Auth para o dashboard:

```bash
htpasswd -nbB NexusAI 'SUA_SENHA'
```

Se o hash gerado tiver `$`, escape cada `$` como `$$` dentro do `.env`.

Exemplo:

```env
DASHBOARD_BASIC_AUTH=NexusAI:$$2y$$05$$...
```

## 4. Providers

Adicione no `.env` as chaves dos providers que quiser usar:

```env
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
GEMINI_API_KEY=
GROQ_API_KEY=
MISTRAL_API_KEY=
XAI_API_KEY=
NOUS_API_KEY=
HF_TOKEN=
NOVITA_API_KEY=
MINIMAX_API_KEY=
```

O compose passa essas variaveis para o Hermes Agent via `env_file`.

## 5. GitHub

Se o Hermes precisar acessar repositorios privados, preencha os tokens:

```env
GITHUB_TOKEN=ghp_...
GH_TOKEN=ghp_...
```

Use um token com o menor escopo possivel. Para repositorios privados, normalmente
`repo` e suficiente em Personal Access Token classico. Em fine-grained tokens,
libere apenas os repositorios necessarios.

## 6. Validar compose

Antes de subir:

```bash
docker compose config
```

Se esse comando falhar, corrija o `.env` antes de continuar.

## 7. Build e subida

```bash
docker compose up -d --build
```

Ver logs:

```bash
docker compose logs -f hermes-agent hermes-workspace open-webui searxng
```

Ver status:

```bash
docker compose ps
```

## 8. Validar APIs

Carregue a key no shell:

```bash
set -a
source .env
set +a
```

Teste a API publica do Hermes:

```bash
curl -fsS https://api-hermes.solucoes-nexus.tech/health
```

Teste modelos via API OpenAI-compatible:

```bash
curl -fsS \
  -H "Authorization: Bearer $API_SERVER_KEY" \
  https://api-hermes.solucoes-nexus.tech/v1/models
```

Teste chat simples:

```bash
curl -fsS https://api-hermes.solucoes-nexus.tech/v1/chat/completions \
  -H "Authorization: Bearer $API_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"hermes-agent","messages":[{"role":"user","content":"Responda apenas: ok"}]}'
```

Teste Open WebUI:

```bash
curl -fsS https://chat.solucoes-nexus.tech/health
```

Teste dashboards internos:

```bash
docker compose exec hermes-agent curl -fsS http://localhost:9119/
```

## 9. Acessos

Hermes Desktop:

```text
URL: https://api-hermes.solucoes-nexus.tech
API key: valor de API_SERVER_KEY
```

OpenAI-compatible clients:

```text
Base URL: https://api-hermes.solucoes-nexus.tech/v1
API key: valor de API_SERVER_KEY
```

Interfaces web:

```text
Hermes Dashboard: https://hermes.solucoes-nexus.tech
Workspace: https://workspace.solucoes-nexus.tech
Open WebUI: https://chat.solucoes-nexus.tech
Kanban: dentro do Hermes Dashboard
```

## 10. Arquitetura de dados

Volumes principais:

```text
hermes-agent-data       Estado do Hermes Agent, config, memoria, kanban e dados persistentes
hermes-workspace-files  Arquivos de trabalho compartilhados em /workspace
open-webui-data         Banco/config propria do Open WebUI
searxng-cache           Cache do SearXNG
```

Open WebUI usa o Hermes Agent como backend em:

```text
http://hermes-agent:8642/v1
```

Ele tambem monta os volumes Hermes em:

```text
/hermes-data  somente leitura
/workspace
```

O banco proprio do Open WebUI continua separado em `/app/backend/data` para nao
misturar schemas internos com os dados do Hermes.

## 11. Atualizar stack

```bash
cd /opt/hermes
git pull
docker compose pull
docker compose up -d --build
docker compose ps
```

Ver logs apos atualizar:

```bash
docker compose logs -f --tail=200 hermes-agent hermes-workspace open-webui searxng
```

## 12. Reiniciar servicos

Reiniciar tudo:

```bash
docker compose restart
```

Reiniciar apenas o Agent:

```bash
docker compose restart hermes-agent
```

Rebuild completo:

```bash
docker compose build --no-cache
docker compose up -d
```

## 13. Diagnostico rapido

Containers:

```bash
docker compose ps
```

Logs do Agent:

```bash
docker compose logs -f hermes-agent
```

Testar healthcheck real do Agent:

```bash
docker compose exec hermes-agent curl -fsS http://localhost:8642/health
```

Logs do Open WebUI:

```bash
docker compose logs -f open-webui
```

Logs do Traefik externo:

```bash
docker logs -f <NOME_CONTAINER_TRAEFIK>
```

Entrar no Hermes Agent:

```bash
docker compose exec hermes-agent bash
```

Ver ferramentas instaladas:

```bash
docker compose exec hermes-agent bash -lc 'jq --version && rg --version && fd --version && python3 --version'
```

Ver tokens GitHub disponiveis dentro do Agent sem imprimir o segredo:

```bash
docker compose exec hermes-agent bash -lc 'test -n "$GITHUB_TOKEN" && echo GITHUB_TOKEN_OK; test -n "$GH_TOKEN" && echo GH_TOKEN_OK'
```

Testar SearXNG interno:

```bash
docker compose exec hermes-agent curl -fsS 'http://searxng:8080/search?q=teste&format=json'
```

## 14. Cuidados

- Nao publique portas diretas neste compose; entrada publica deve passar pelo Traefik.
- Nao commite `.env`; ele esta no `.gitignore`.
- Mantenha `API_SERVER_KEY`, `OPENWEBUI_SECRET_KEY` e `SEARXNG_SECRET` fortes.
- Se trocar `OPENWEBUI_ADMIN_PASSWORD` depois do primeiro boot, talvez precise alterar a senha pela UI ou recriar o volume `open-webui-data`.
- Apagar volumes remove dados persistentes. Nao use `docker compose down -v` em producao sem backup.
