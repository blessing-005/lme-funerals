param([int]$Port = 4173)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "docs")
$py = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } elseif (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { throw "Python is required." }
Write-Host "Review: http://localhost:$Port"
& $py -m http.server $Port
