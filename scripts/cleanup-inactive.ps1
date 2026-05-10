param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("blue", "green")]
  [string]$Target
)

$inactive = if ($Target -eq "blue") { "green" } else { "blue" }

$repoRoot = Split-Path -Parent $PSScriptRoot
$activeFile = Join-Path $repoRoot "nginx\conf.d\active-upstream.conf"
$backupFile = $null
if (Test-Path $activeFile) {
  $timestamp = Get-Date -Format "yyyyMMddHHmmss"
  $backupFile = "$activeFile.bak.$timestamp"
  Copy-Item -Path $activeFile -Destination $backupFile -Force
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

@"
# Primary: $Target (backup removed).
upstream app_active {
    server app_$Target:8000 max_fails=2 fail_timeout=10s;
}
"@ | Set-Content -Path $activeFile -Encoding Ascii

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
  if ($backupFile) {
    Copy-Item -Path $backupFile -Destination $activeFile -Force
    docker compose exec -T nginx nginx -s reload | Out-Null
  }
  docker compose ps
  docker compose logs --no-color nginx
  exit 1
}

docker compose stop "app_$inactive" | Out-Null
docker compose rm -f "app_$inactive" | Out-Null

Write-Host "Removed inactive app_$inactive."
