# Zero-Downtime-Traffic-Shifter

Blue/green traffic switching demo with NGINX and FastAPI.

## Quick start

```bash
docker compose up --build
```

To include monitoring stack:

```bash
docker compose --profile monitoring up --build
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

## CI/CD (GitHub Actions)

The workflow builds and pushes the image to GHCR, then spins up blue/green locally on the runner, smoke-tests green, and switches traffic:

- Build and push: `ghcr.io/<owner>/<repo>/zdt-shifter:<sha>` and `:latest`
- Start stack with `ZDT_IMAGE` so the compose file uses the just-built image
- Health-check green on `http://localhost:8081/health`
- Switch traffic to green via `scripts/switch-traffic.sh`

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



#end