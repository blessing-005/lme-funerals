$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Node.js is required." }
node scripts/build.mjs
if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
