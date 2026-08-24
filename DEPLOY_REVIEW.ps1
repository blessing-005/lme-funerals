param([switch]$NoOpen)
$ErrorActionPreference = 'Stop'
$env:PYTHONUTF8 = '1'

function Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}
function Need([string]$Command) {
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Command is required but was not found in PATH."
    }
}

Step 'Checking prerequisites'
Need git
Need node
Need npm
Need gh
Need python
Write-Host (git --version)
Write-Host (node --version)
Write-Host (gh --version | Select-Object -First 1)

Step 'Building and validating'
npm run build
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
python -X utf8 tests/qa.py
if ($LASTEXITCODE -ne 0) { throw 'Validation failed.' }

Step 'Authenticating to GitHub'
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    gh auth login --web
    if ($LASTEXITCODE -ne 0) { throw 'GitHub authentication failed.' }
}
$owner = (gh api user --jq .login).Trim()
if (-not $owner) { throw 'Could not determine the authenticated GitHub username.' }

$repo = $env:REVIEW_REPO
if (-not $repo) { $repo = 'lme-funerals' }
$full = "$owner/$repo"
Write-Host "Repository: $full"

Step 'Preparing Git repository'
if (-not (Test-Path .git)) {
    git init -b main | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Git initialisation failed.' }
} else {
    git branch -M main
}
git config user.name $owner
git config user.email "$owner@users.noreply.github.com"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m 'Publish client review website' | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
}

$repoExists = $true
gh repo view $full *> $null
if ($LASTEXITCODE -ne 0) { $repoExists = $false }

if (-not $repoExists) {
    Step 'Creating GitHub repository'
    gh repo create $full --public --source . --remote origin
    if ($LASTEXITCODE -ne 0) { throw 'Repository creation failed.' }
} else {
    Step 'Connecting existing GitHub repository'
    $remote = ''
    try { $remote = (git remote get-url origin 2>$null).Trim() } catch { $remote = '' }
    if (-not $remote) {
        git remote add origin "https://github.com/$full.git"
    } elseif ($remote -notmatch [regex]::Escape($full)) {
        throw "Existing origin points to '$remote', not '$full'. Refusing to overwrite an unrelated repository."
    }
}

Step 'Pushing website'
git fetch origin main *> $null
$remoteMainExists = ($LASTEXITCODE -eq 0)
if ($remoteMainExists) {
    # Safe update for an existing review repository. Fetch establishes the lease first.
    git push --force-with-lease -u origin main
} else {
    git push -u origin main
}
if ($LASTEXITCODE -ne 0) { throw 'GitHub push failed.' }

Step 'Configuring GitHub Pages'
$tmp = Join-Path $env:TEMP "pages-$repo.json"
$json = '{"source":{"branch":"main","path":"/docs"}}'
[System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($false)))

gh api "repos/$full/pages" *> $null
$pagesExists = ($LASTEXITCODE -eq 0)
if ($pagesExists) {
    gh api -X PUT "repos/$full/pages" --input $tmp *> $null
} else {
    gh api -X POST "repos/$full/pages" --input $tmp *> $null
}
$pagesCode = $LASTEXITCODE
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
if ($pagesCode -ne 0) {
    Write-Warning 'The repository was pushed, but the Pages API did not confirm configuration immediately. Check Repository Settings > Pages if GitHub does not publish automatically.'
}

$url = "https://$owner.github.io/$repo/"
[System.IO.File]::WriteAllText((Join-Path (Get-Location) '.last_deploy_url'), $url, (New-Object System.Text.UTF8Encoding($false)))
Step 'Deployment submitted'
Write-Host "Review URL: $url" -ForegroundColor Green
Write-Host 'GitHub Pages can take a minute or two to refresh.'
if (-not $NoOpen) { Start-Process $url }
