# Hermes VPS deployment

This compose stack is intended for one VPS running:

- Hermes Agent gateway API on `https://api-hermes.solucoes-nexus.tech`
- Hermes Agent dashboard on `https://hermes.solucoes-nexus.tech`
- Hermes Workspace on `https://workspace.solucoes-nexus.tech`
- SearXNG as an internal-only search backend for Hermes Agent

It assumes Traefik is already running separately on the same Docker host with
the Docker provider enabled and `exposedbydefault=false`. This stack only
declares Traefik labels; it does not create a Traefik container.

## DNS

Create these `A` records pointing to the VPS public IPv4:

- `hermes.solucoes-nexus.tech`
- `workspace.solucoes-nexus.tech`
- `api-hermes.solucoes-nexus.tech`

## Environment

Copy `.env.example` to `.env` and replace every `change-me-*` value.

Generate a strong API key:

```bash
openssl rand -hex 32
```

Generate dashboard basic-auth:

```bash
htpasswd -nbB admin 'your-password'
```

If the generated bcrypt hash contains `$`, escape each `$` as `$$` in `.env`,
because Docker Compose treats `$` as interpolation syntax.

Provider keys are intentionally open-ended. Add any provider variable supported
by Hermes Agent to `.env`; `env_file` passes it through to the agent container.

Your external Traefik stack owns `ACME_EMAIL`, ports `80/443`, and the
`traefik-letsencrypt` volume. Do not duplicate them in this Hermes stack.

## Run

```bash
docker compose up -d --build
docker compose logs -f hermes-agent hermes-workspace searxng
```

Health checks:

```bash
curl -fsS https://api-hermes.solucoes-nexus.tech/health
curl -fsS -H "Authorization: Bearer $API_SERVER_KEY" https://api-hermes.solucoes-nexus.tech/v1/models
```

Hermes Desktop should use:

- URL: `https://api-hermes.solucoes-nexus.tech`
- API key: same value as `API_SERVER_KEY`

OpenAI-compatible clients usually need the `/v1` base URL:

- `https://api-hermes.solucoes-nexus.tech/v1`
