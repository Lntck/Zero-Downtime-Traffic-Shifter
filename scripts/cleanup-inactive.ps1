param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("blue", "green")]
  [string]$Target
)

$inactive = if ($Target -eq "blue") { "green" } else { "blue" }

$repoRoot = Split-Path -Parent $PSScriptRoot
$activeFile = Join-Path $repoRoot "nginx\conf.d\active-upstream.conf"

@"
# Primary: $Target (backup removed).
upstream app_active {
    server app_$Target:8000 max_fails=2 fail_timeout=10s;
}
"@ | Set-Content -Path $activeFile -Encoding Ascii

docker compose exec -T nginx nginx -s reload
docker compose stop "app_$inactive" | Out-Null
docker compose rm -f "app_$inactive" | Out-Null

Write-Host "Removed inactive app_$inactive."
