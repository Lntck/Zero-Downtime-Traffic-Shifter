param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("blue", "green")]
  [string]$Target
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$activeFile = Join-Path $repoRoot "nginx\conf.d\active-upstream.conf"

if ($Target -eq "blue") {
@"
# Primary: blue, backup: green.
upstream app_active {
    server app_blue:8000 max_fails=2 fail_timeout=10s;
    server app_green:8000 backup;
}
"@ | Set-Content -Path $activeFile -Encoding Ascii
} else {
@"
# Primary: green, backup: blue.
upstream app_active {
    server app_green:8000 max_fails=2 fail_timeout=10s;
    server app_blue:8000 backup;
}
"@ | Set-Content -Path $activeFile -Encoding Ascii
}

docker compose exec -T nginx nginx -s reload

Write-Host "Switched active upstream to $Target."
