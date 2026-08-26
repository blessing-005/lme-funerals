# LME Funerals

Production-review website for the existing `lme-funerals` repository identity. The site is a dependency-light static build for GitHub Pages.

## Build and QA

```powershell
./BUILD.ps1
./QA.ps1
./START_REVIEW.ps1
```

Public files are generated into `docs/`. Review pages intentionally use `noindex,nofollow`; remove that directive only after client approval and production canonical-domain confirmation.
