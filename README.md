# Zero-Downtime-Traffic-Shifter

Blue/green traffic switching demo with NGINX and FastAPI.

## Quick start

```bash
docker compose up --build
```

Open `http://localhost/` to see the active version, and `http://localhost/healthz` for the proxy health endpoint.

## Traffic switch (local dev)

Windows:

```powershell
./scripts/switch-traffic.ps1 -Target green
```

Bash:

```bash
./scripts/switch-traffic.sh green
```

These scripts rewrite `nginx/conf.d/active-upstream.conf` and reload NGINX. When green is active, blue is configured as a backup server so 5xx/timeouts fail over automatically.