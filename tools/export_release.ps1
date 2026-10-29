# Builds the signed Google Play bundle: build/dont-trust-your-eyes.aab
# The upload key stays outside the repo (see docs/PLAY_STORE.md):
#   powershell -ExecutionPolicy Bypass -File tools/export_release.ps1
# APK to share directly (real phones only, arm 32/64-bit):
#   powershell -ExecutionPolicy Bypass -File tools/export_release.ps1 -Preset "Android APK" -Output build/DontTrustYourEyes.apk
# Before each new upload, raise version/code (and version/name) in export_presets.cfg.
param(
	[string]$Signing = "$env:USERPROFILE\dtye-signing\signing.env",
	[string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.5.1-stable_win64_console.exe",
	[string]$Preset = "Android Play",
	[string]$Output = "build/dont-trust-your-eyes.aab"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $Signing)) { throw "Upload key settings not found: $Signing" }
Get-Content $Signing | Where-Object { $_ -match '^\s*([A-Z_]+)=(.+)$' } | ForEach-Object {
	Set-Item "env:$($Matches[1])" $Matches[2].Trim()
}

New-Item -ItemType Directory -Force (Join-Path $root "build") | Out-Null
$template = @()
if ($Preset -eq "Android Play" -and -not (Test-Path (Join-Path $root "android/build"))) { $template = @("--install-android-build-template") }
$env:GRADLE_OPTS = "-Dorg.gradle.daemon=false"  # a lingering daemon would keep this script waiting
$ErrorActionPreference = "Continue"  # Godot prints warnings on stderr; only its exit code counts
& $Godot --headless --path $root @template --export-release $Preset $Output
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $root $Output))) { throw "Export failed (exit code $LASTEXITCODE)" }
Write-Host "OK: $Output"
