param([int]$Port=4173)
$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
& ./BUILD.ps1
Write-Host "Local review: http://localhost:$Port" -ForegroundColor Green
python -m http.server $Port --directory docs
