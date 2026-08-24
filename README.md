# LME Funerals

Private client-review website.

## Local preview
PowerShell:
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
Unblock-File .\START_REVIEW.ps1
.\START_REVIEW.ps1
```

## Deploy to GitHub Pages
```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
Unblock-File .\DEPLOY_REVIEW.ps1
.\DEPLOY_REVIEW.ps1
```

The review build is intentionally `noindex, nofollow`. Internal audit files are under `internal/` and are not copied into `docs/`.
