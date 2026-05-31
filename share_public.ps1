param(
    [string]$CanvasId = "",
    [string]$Password = "",
    [switch]$NoTunnel
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerUrl = "http://127.0.0.1:3000"
$serverProcess = $null

function Get-LatestCanvasId {
    $canvasDir = Join-Path $Root "data\canvases"
    if (-not (Test-Path $canvasDir)) {
        throw "data\canvases was not found."
    }
    $items = Get-ChildItem -LiteralPath $canvasDir -Filter "*.json" | ForEach-Object {
        try {
            $raw = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            $data = $raw | ConvertFrom-Json
            if (-not $data.deleted_at) {
                [PSCustomObject]@{
                    Id = [string]$data.id
                    Title = [string]$data.title
                    UpdatedAt = [int64]($data.updated_at -as [int64])
                }
            }
        } catch {}
    } | Where-Object { $_ -and $_.Id } | Sort-Object UpdatedAt -Descending
    if (-not $items) {
        throw "No shareable canvas found. Create or open a canvas first."
    }
    return $items[0].Id
}

function Test-Server {
    try {
        Invoke-RestMethod -Uri "$ServerUrl/api/share/status" -Method Get -TimeoutSec 1 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Wait-Server {
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-Server) { return }
        Start-Sleep -Milliseconds 500
    }
    throw "Local server startup timed out."
}

if (-not (Test-Server)) {
    $python = Join-Path $Root "python\python.exe"
    if (-not (Test-Path $python)) { $python = "python" }
    $serverProcess = Start-Process -FilePath $python -ArgumentList "main.py" -WorkingDirectory $Root -WindowStyle Hidden -PassThru
    Wait-Server
}

$Password = if ($Password) { $Password } else { [guid]::NewGuid().ToString("N") }
$configBody = @{
    enabled = $true
    password = $Password
    protect_public_root = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "$ServerUrl/api/share/config" -Method Put -ContentType "application/json" -Body $configBody | Out-Null

$publicPath = "/canvas"
$localUrl = "$ServerUrl$publicPath"
$lanIp = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notmatch "^(127\.|169\.254\.)" -and $_.PrefixOrigin -ne "WellKnown" } |
    Select-Object -First 1 -ExpandProperty IPAddress

Write-Host ""
Write-Host "Public canvas website is enabled." -ForegroundColor Green
Write-Host "Local URL: $localUrl"
if ($lanIp) {
    Write-Host "Same Wi-Fi/LAN URL: http://$lanIp`:3000$publicPath"
}

if ($NoTunnel) {
    Write-Host ""
    Write-Host "Public tunnel skipped."
    return
}

$toolsDir = Join-Path $Root "tools"
New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
$cloudflared = Join-Path $toolsDir "cloudflared.exe"

if (-not (Test-Path $cloudflared)) {
    Write-Host ""
    Write-Host "Downloading public tunnel tool: cloudflared..."
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cloudflared
}

Write-Host ""
Write-Host "Starting public tunnel. When you see https://*.trycloudflare.com, send that URL plus $publicPath to your friend." -ForegroundColor Cyan
Write-Host "Example: https://xxxx.trycloudflare.com$publicPath"
Write-Host "Keep this window open while friends are using the canvas."
Write-Host ""

try {
    & $cloudflared tunnel --url $ServerUrl
} finally {
    if ($serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
