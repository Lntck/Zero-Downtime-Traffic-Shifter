# Zero-Downtime-Traffic-Shifter

Blue/green traffic switching demo with NGINX and FastAPI.

## Quick start

```bash
docker compose up --build
```

Open `http://localhost/` to see the active version, and `http://localhost/healthz` for the proxy health endpoint.

## Manual switch (local dev)

Edit `nginx/conf.d/active-upstream.conf` to point `app_active` at `app_green`, then reload NGINX:

```bash
docker compose exec nginx nginx -s reload
```