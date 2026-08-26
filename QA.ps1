$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path docs)) { & ./BUILD.ps1 }
python tests/qa.py
if ($LASTEXITCODE -ne 0) { throw 'QA failed.' }
