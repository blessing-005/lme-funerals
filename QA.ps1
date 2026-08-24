$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) { throw "Python is required." }
$py = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }
& $py tests/qa.py
if ($LASTEXITCODE -ne 0) { throw "QA failed with exit code $LASTEXITCODE" }
