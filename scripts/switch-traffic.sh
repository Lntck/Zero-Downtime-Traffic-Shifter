#!/usr/bin/env bash
set -euo pipefail

target=""
cleanup="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    blue|green)
      target="$1"
      ;;
    --cleanup)
      cleanup="true"
      ;;
    *)
      echo "Usage: $0 blue|green [--cleanup]"
      exit 1
      ;;
  esac
  shift
done

if [[ "$target" != "blue" && "$target" != "green" ]]; then
  echo "Usage: $0 blue|green [--cleanup]"
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

if [[ "$target" == "blue" ]]; then
  cat > "$active_file" <<'EOF'
# Primary: blue, backup: green.
upstream app_active {
    server app_blue:8000 max_fails=2 fail_timeout=10s;
    server app_green:8000 backup;
}
EOF
else
  cat > "$active_file" <<'EOF'
# Primary: green, backup: blue.
upstream app_active {
    server app_green:8000 max_fails=2 fail_timeout=10s;
    server app_blue:8000 backup;
}
EOF
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

for i in {1..10}; do
  if docker compose exec -T nginx nginx -s reload; then
    if [[ "$cleanup" == "true" ]]; then
      docker compose stop "app_${inactive}" || true
      docker compose rm -f "app_${inactive}" || true
    fi
    echo "Switched active upstream to $target."
    exit 0
  fi
  echo "Waiting for nginx to be ready..."
  sleep 1
done

if [[ -n "$backup_file" ]]; then
  cp "$backup_file" "$active_file"
  docker compose exec -T nginx nginx -s reload || true
fi

docker compose ps
docker compose logs --no-color nginx
exit 1
