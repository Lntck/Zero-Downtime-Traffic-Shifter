#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ "$target" != "blue" && "$target" != "green" ]]; then
  echo "Usage: $0 blue|green"
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
active_file="$repo_root/nginx/conf.d/active-upstream.conf"

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

docker compose exec nginx nginx -s reload

echo "Switched active upstream to $target."
