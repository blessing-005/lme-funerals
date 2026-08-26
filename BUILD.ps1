$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js is required.' }
npm run build
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
