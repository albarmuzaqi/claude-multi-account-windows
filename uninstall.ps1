<#
.SYNOPSIS
  Hapus shortcut dan launcher Claude N. Data login/chat tetap disimpan, kecuali pakai -RemoveData.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Number 2
#>
param(
    [ValidateRange(2, 99)][int]$Number = 2,
    # Ikut hapus data akun (login, chat, config CLI). Nggak bisa dibalikin.
    [switch]$RemoveData
)

$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$installDir = Join-Path $env:LOCALAPPDATA "ClaudeMultiAccount\akun$Number"

Get-Process -Name "Claude$Number" -ErrorAction SilentlyContinue | Stop-Process -Force

$targets = @(
    (Join-Path $desktop "Claude $Number.lnk"),
    (Join-Path $startMenu "Claude $Number.lnk"),
    (Join-Path $desktop "Claude Code $Number.lnk"),
    (Join-Path $env:USERPROFILE ".local\bin\claude$Number.cmd"),
    $installDir
)
if ($RemoveData) {
    $targets += (Join-Path $env:USERPROFILE ".claude-desktop-akun$Number"), (Join-Path $env:USERPROFILE ".claude-akun$Number")
}

foreach ($t in $targets) {
    if (Test-Path $t) { Remove-Item $t -Recurse -Force; Write-Host "Dihapus: $t" }
}

Write-Host "Claude $Number udah dihapus." -ForegroundColor Green
if (-not $RemoveData) { Write-Host "Data akun masih ada di $env:USERPROFILE\.claude-desktop-akun$Number (pakai -RemoveData buat hapus)." }
