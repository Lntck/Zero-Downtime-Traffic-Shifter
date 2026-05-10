# Zero-Downtime-Traffic-Shifter

Blue/green traffic switching demo with NGINX and FastAPI. The project runs two app versions side-by-side, verifies health, then switches traffic with a safe NGINX reload. A monitoring profile adds Prometheus, Grafana, and Loki for observability.

## Features

- Blue/green routing with NGINX upstreams
- Passive failover (5xx/timeouts fall back to backup)
- One-command local demo with Docker Compose
- CI/CD pipeline that builds, tests, and switches traffic
- Monitoring stack with dashboards and log labels for app color/version

## Architecture

- app_blue, app_green: FastAPI containers (internal port 8000)
- nginx: reverse proxy (port 80)
- monitoring profile: nginx_exporter, prometheus, loki, promtail, grafana

Traffic flow:

1) NGINX proxies to the active upstream (blue or green).
2) The switch scripts rewrite the active-upstream file.
3) NGINX reloads config without downtime.
4) If the active upstream fails, NGINX falls back to the backup server.

## Requirements

- Docker Engine with the docker compose plugin
- Git
- Optional: Ansible (for provisioning a host)

## Quick start

```bash
docker compose up --build
```

To include the monitoring stack:

```bash
docker compose --profile monitoring up --build
```

Open `http://localhost/` to see the active version, and `http://localhost/healthz` for the proxy health endpoint.

## Configuration

Environment variables used by the app:

- `APP_VERSION`: version label shown in responses
- `APP_COLOR`: color label shown in responses and headers

Compose override:

- `ZDT_IMAGE`: image tag used by app_blue/app_green (e.g. `ghcr.io/owner/repo/zdt-shifter:sha`)

## Ports

- 80: NGINX
- 8080: app_blue (direct access)
- 8081: app_green (direct access)
- 3000: Grafana (monitoring profile)
- 9090: Prometheus (monitoring profile)
- 3100: Loki (monitoring profile)
- 9113: NGINX exporter (monitoring profile)

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

## CI/CD (GitHub Actions)

The workflow builds and pushes the image to GHCR, then spins up blue/green locally on the runner, smoke-tests green, and switches traffic:

- Build and push: `ghcr.io/<owner>/<repo>/zdt-shifter:<sha>` and `:latest`
- Start stack with `ZDT_IMAGE` so the compose file uses the just-built image
- Health-check green on `http://localhost:8081/health`
- Switch traffic to green via `scripts/switch-traffic.sh`

Notes:

- GHCR requires lowercase repository names in image tags.
- The workflow exports `ZDT_IMAGE` so compose uses the newly built image.

## Monitoring (Prometheus + Grafana + Loki)

Start the monitoring profile:

```bash
docker compose --profile monitoring up -d
```

Endpoints:

- Grafana: `http://localhost:3000` (admin/admin)
- Prometheus: `http://localhost:9090`
- Loki: `http://localhost:3100`

The "Zero-Downtime Traffic" dashboard is provisioned on startup. NGINX access logs are JSON and include upstream color/version for log-based panels.

LogQL examples:

- 5xx per minute: `sum(rate({job="nginx",status=~"5.."}[1m]))`
- Requests by color: `sum by (upstream_color) (rate({job="nginx"}[1m]))`

## Alerts

Create a Grafana alert using the 5xx LogQL query above to notify on error spikes after a deploy.

## Automation (Ansible)

Example run (Ubuntu host):

```bash
ansible-playbook -i ansible/inventory.example.ini ansible/site.yml \
  -e "repo_url=https://github.com/<owner>/Zero-Downtime-Traffic-Shifter.git" \
  -e "app_user=ubuntu"
```

## Cleanup

After a successful switch, remove the inactive app container and drop the backup server:

```powershell
./scripts/cleanup-inactive.ps1 -Target green
```

```bash
./scripts/cleanup-inactive.sh green
```

## Troubleshooting

- Ports already in use: stop other services on 80/3000/9090/3100 or change compose ports.
- CI/CD pull errors: verify GHCR permissions and lowercase image name.
- NGINX not routing: check `nginx/conf.d/active-upstream.conf` and reload.

## Contributing

Issues and pull requests are welcome. Please include:

- A clear description of the change
- Steps to reproduce (for bugs)
- Any screenshots or logs that help

## License

MIT License. See LICENSE.