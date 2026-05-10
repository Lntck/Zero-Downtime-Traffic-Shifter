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

cat > "$active_file" <<EOF
# Primary: ${target} (backup removed).
upstream app_active {
    server app_${target}:8000 max_fails=2 fail_timeout=10s;
}
EOF

docker compose exec -T nginx nginx -s reload
docker compose stop "app_${inactive}" || true
docker compose rm -f "app_${inactive}" || true

echo "Removed inactive app_${inactive}."
