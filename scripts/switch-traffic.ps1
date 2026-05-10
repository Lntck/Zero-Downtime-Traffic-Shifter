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

$existingId = docker compose ps -a -q nginx
if (-not $existingId) {
  Write-Host "Nginx container not found. Run: docker compose up -d nginx"
  exit 1
}

$runningId = docker compose ps -q nginx
if (-not $runningId) {
  docker compose start nginx
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start nginx."
    docker compose ps
    docker compose logs --no-color nginx
    exit 1
  }
}

$reloaded = $false
for ($i = 0; $i -lt 10; $i++) {
  docker compose exec -T nginx nginx -s reload
  if ($LASTEXITCODE -eq 0) {
    $reloaded = $true
    break
  }
  Write-Host "Waiting for nginx to be ready..."
  Start-Sleep -Seconds 1
}

if (-not $reloaded) {
  docker compose ps
  docker compose logs --no-color nginx
  exit 1
}

Write-Host "Switched active upstream to $Target."
