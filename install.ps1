<#
.SYNOPSIS
  Pasang Claude kedua (ketiga, dst.) di Windows dengan akun terpisah, icon berwarna, dan tombol taskbar sendiri.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1
  powershell -ExecutionPolicy Bypass -File install.ps1 -Number 3 -Color blue
#>
param(
    # Nomor akun. Akun 1 = Claude bawaan, jadi mulai dari 2.
    [ValidateRange(2, 99)][int]$Number = 2,
    # Warna icon: green, blue, purple, pink, teal, yellow, red.
    [ValidateSet('green', 'blue', 'purple', 'pink', 'teal', 'yellow', 'red')][string]$Color = 'green',
    # Lewati bagian Claude Code CLI (claudeN di terminal).
    [switch]$NoCli
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$hueShift = @{ green = 125; blue = 195; purple = 255; pink = 305; teal = 160; yellow = 30; red = 345 }[$Color]

$name = "Claude $Number"
$appId = "ClaudeMultiAccount.Akun$Number"
$dataDir = Join-Path $env:USERPROFILE ".claude-desktop-akun$Number"
$installDir = Join-Path $env:LOCALAPPDATA "ClaudeMultiAccount\akun$Number"
$iconPath = Join-Path $installDir "claude$Number.ico"
$launcherExe = Join-Path $installDir "Claude$Number.exe"
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

function Step($msg) { Write-Host "-> $msg" -ForegroundColor Cyan }

# 1. Cari aplikasi Claude desktop (versi Microsoft Store/MSIX atau installer biasa).
Step 'Mencari aplikasi Claude desktop'
$pkg = Get-AppxPackage -Name AnthropicPBC.Claude -ErrorAction SilentlyContinue | Select-Object -First 1
$iconSource = $null
if ($pkg) {
    $claudeExe = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\claude-desktop-msstore.exe'
    if (-not (Test-Path $claudeExe)) { throw "Alias $claudeExe nggak ketemu. Coba buka Claude sekali dari Start Menu, lalu jalankan ulang." }
    $iconSource = Get-ChildItem (Join-Path $pkg.InstallLocation 'assets') -Filter 'Square44x44Logo.targetsize-256*.png' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    $exeForIcon = Join-Path $pkg.InstallLocation 'app\Claude.exe'
}
else {
    $claudeExe = Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'
    if (-not (Test-Path $claudeExe)) { throw 'Aplikasi Claude desktop belum terpasang. Install dulu dari https://claude.ai/download' }
    $exeForIcon = $claudeExe
}
Write-Host "   $claudeExe"

New-Item -ItemType Directory -Force $installDir, $dataDir | Out-Null

# 2. Bikin icon Claude dengan warna lain.
Step "Bikin icon warna $Color"
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -Path (Join-Path $here 'src\Recolor.cs')
if ($iconSource) { $orig = [System.Drawing.Bitmap]::FromFile($iconSource) }
else { $orig = [System.Drawing.Icon]::ExtractAssociatedIcon($exeForIcon).ToBitmap() }
$colored = [IconRecolor]::ShiftHue($orig, $hueShift)

$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = New-Object System.Collections.Generic.List[byte[]]
foreach ($s in $sizes) {
    $b = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.SmoothingMode = 'AntiAlias'
    $g.DrawImage($colored, 0, 0, $s, $s); $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
    $pngs.Add($ms.ToArray())
}
$out = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter $out
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $dim = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }
    $bw.Write([byte]$dim); $bw.Write([byte]$dim); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Flush()
[IO.File]::WriteAllBytes($iconPath, $out.ToArray())
$orig.Dispose(); $colored.Dispose()

# 3. Compile launcher kecil yang kasih jendela akun ini ID taskbar sendiri.
Step "Bikin launcher $name"
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
$src = Get-Content (Join-Path $here 'src\Launcher.cs.template') -Raw
$values = @{ '__APP_ID__' = $appId; '__DISPLAY_NAME__' = $name; '__DATA_DIR__' = $dataDir; '__ICON_PATH__' = $iconPath; '__CLAUDE_EXE__' = $claudeExe }
foreach ($k in $values.Keys) { $src = $src.Replace($k, $values[$k]) }
$srcPath = Join-Path $installDir 'Launcher.cs'
Set-Content -Path $srcPath -Value $src -Encoding UTF8
Get-Process -Name "Claude$Number" -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $launcherExe } | Stop-Process -Force
$cscOut = & $csc /nologo /target:winexe /optimize "/win32icon:$iconPath" "/out:$launcherExe" /r:System.Management.dll $srcPath 2>&1
if ($LASTEXITCODE -ne 0) { throw "Gagal compile launcher:`n$cscOut" }

# 4. Shortcut di Desktop dan Start Menu, dengan ID taskbar yang sama.
Step 'Bikin shortcut Desktop dan Start Menu'
$ws = New-Object -ComObject WScript.Shell
foreach ($lnkPath in (Join-Path $desktop "$name.lnk"), (Join-Path $startMenu "$name.lnk")) {
    $l = $ws.CreateShortcut($lnkPath)
    $l.TargetPath = $launcherExe
    $l.WorkingDirectory = $installDir
    $l.IconLocation = "$iconPath,0"
    $l.Description = "Claude desktop - akun $Number"
    $l.Save()
    $r = Start-Process $launcherExe -ArgumentList '--set-lnk', "`"$lnkPath`"" -Wait -PassThru
    if ($r.ExitCode -ne 0) { Write-Warning "ID taskbar gagal dipasang di $lnkPath" }
}

# 5. Claude Code CLI: perintah claudeN dengan folder config sendiri.
if (-not $NoCli) {
    Step "Bikin perintah claude$Number untuk Claude Code CLI"
    $binDir = Join-Path $env:USERPROFILE '.local\bin'
    New-Item -ItemType Directory -Force $binDir | Out-Null
    $cmdPath = Join-Path $binDir "claude$Number.cmd"
    $cmd = "@echo off`r`nset `"CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-akun$Number`"`r`nclaude %*`r`n"
    [IO.File]::WriteAllText($cmdPath, $cmd)
    New-Item -ItemType Directory -Force (Join-Path $env:USERPROFILE ".claude-akun$Number") | Out-Null

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $binDir) {
        [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ";$binDir"), 'User')
        Write-Host "   $binDir ditambahin ke PATH (buka terminal baru biar kebaca)"
    }

    $wt = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe'
    $l = $ws.CreateShortcut((Join-Path $desktop "Claude Code $Number.lnk"))
    if (Test-Path $wt) {
        $l.TargetPath = $wt
        $l.Arguments = "new-tab --title `"Claude Code $Number`" --suppressApplicationTitle -d `"$env:USERPROFILE`" cmd /k `"$cmdPath`""
    }
    else {
        $l.TargetPath = Join-Path $env:WINDIR 'System32\cmd.exe'
        $l.Arguments = "/k `"$cmdPath`""
    }
    $l.WorkingDirectory = $env:USERPROFILE
    $l.IconLocation = "$iconPath,0"
    $l.Description = "Claude Code - akun $Number"
    $l.Save()

    if (-not (Get-Command claude -ErrorAction SilentlyContinue) -and -not (Test-Path (Join-Path $binDir 'claude.exe'))) {
        Write-Host '   Claude Code CLI belum terpasang. Install: irm https://claude.ai/install.ps1 | iex' -ForegroundColor Yellow
    }
}

& "$env:WINDIR\System32\ie4uinit.exe" -show 2>$null

Write-Host ''
Write-Host "Selesai! Buka '$name' dari Desktop atau Start Menu, lalu login pakai akun ke-$Number." -ForegroundColor Green
Write-Host "Data akun ini disimpan di $dataDir"
