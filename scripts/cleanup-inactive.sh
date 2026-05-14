#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ "$target" != "blue" && "$target" != "green" ]]; then
  echo "Usage: $0 blue|green"
  exit 1
fi

inactive="blue"
if [[ "$target" == "blue" ]]; then
  inactive="green"
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
active_file="$repo_root/nginx/conf.d/active-upstream.conf"
backup_file=""
if [[ -f "$active_file" ]]; then
  backup_file="$active_file.bak.$(date +%Y%m%d%H%M%S)"
  cp "$active_file" "$backup_file"
fi

existing_id=$(docker compose ps -a -q nginx || true)
if [[ -z "$existing_id" ]]; then
  echo "Nginx container not found. Run: docker compose up -d nginx"
  exit 1
fi

running_id=$(docker compose ps -q nginx || true)
if [[ -z "$running_id" ]]; then
  if ! docker compose start nginx; then
    echo "Failed to start nginx."
    docker compose ps
    docker compose logs --no-color nginx
    exit 1
  fi
fi

cat > "$active_file" <<EOF
# Primary: ${target} (backup removed).
upstream app_active {
    server app_${target}:8000 max_fails=2 fail_timeout=10s;
}
EOF

reloaded="false"
for i in {1..10}; do
  if docker compose exec -T nginx nginx -s reload; then
    reloaded="true"
    break
  fi
  echo "Waiting for nginx to be ready..."
  sleep 1
done

if [[ "$reloaded" != "true" ]]; then
  if [[ -n "$backup_file" ]]; then
    cp "$backup_file" "$active_file"
    docker compose exec -T nginx nginx -s reload || true
  fi
  docker compose ps
  docker compose logs --no-color nginx
  exit 1
fi

docker compose stop "app_${inactive}" || true
docker compose rm -f "app_${inactive}" || true

echo "Removed inactive app_${inactive}."
