param(
  [string]$Owner = "",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $SkipBuild) {
  & ./BUILD.ps1
  & ./QA.ps1
}

foreach ($command in @('git', 'gh')) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $command"
  }
}

gh auth status
if ($LASTEXITCODE -ne 0) {
  throw "GitHub authentication is required. Run gh auth login."
}

if (-not $Owner) {
  $Owner = (gh api user --jq .login).Trim()
}
if (-not $Owner) { throw "Unable to resolve the authenticated GitHub owner." }

$repo = Split-Path $PSScriptRoot -Leaf
$target = "$Owner/$repo"
$hadGit = Test-Path .git

if (-not $hadGit) {
  git init
  git branch -M main
}

$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
  $remoteMatch = [regex]::Match($existingRemote, 'github\.com[:/](?<slug>[^/]+/[^/.]+)')
  if ($remoteMatch.Success) {
    $target = $remoteMatch.Groups['slug'].Value
  }
}

gh repo view $target --json nameWithOwner 2>$null | Out-Null
$repoExists = $LASTEXITCODE -eq 0
if (-not $repoExists) {
  $visibility = (Read-Host "Repository $target does not exist. Create it as public or private? [public]").Trim().ToLowerInvariant()
  if (-not $visibility) { $visibility = 'public' }
  if ($visibility -notin @('public', 'private')) { throw "Visibility must be public or private." }
  if ($visibility -eq 'private') {
    gh repo create $target --private --source . --remote origin
  } else {
    gh repo create $target --public --source . --remote origin
  }
  if ($LASTEXITCODE -ne 0) { throw "Repository creation failed for $target." }
  $repoExists = $true
}

if (-not (git remote get-url origin 2>$null)) {
  git remote add origin "https://github.com/$target.git"
}

if (-not (git config user.name)) { git config user.name $Owner }
if (-not (git config user.email)) { git config user.email "$Owner@users.noreply.github.com" }

git add .
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -m "Production review upgrade"
  if ($LASTEXITCODE -ne 0) { throw "Git commit failed for $target." }
}

if ($repoExists) {
  git fetch origin main 2>$null
  if ($LASTEXITCODE -eq 0) {
    git merge-base --is-ancestor origin/main HEAD 2>$null
    if ($LASTEXITCODE -ne 0) {
      git merge origin/main --allow-unrelated-histories -s ours -m "Preserve remote history for production upgrade"
      if ($LASTEXITCODE -ne 0) { throw "Remote history merge failed for $target." }
    }
  }
}

git push -u origin main
if ($LASTEXITCODE -ne 0) { throw "Push failed for $target." }

gh api "repos/$target/pages" 2>$null | Out-Null
$pagesExists = $LASTEXITCODE -eq 0
if (-not $pagesExists) {
  gh api --method POST "repos/$target/pages" -f build_type=workflow | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "GitHub Pages could not be configured for $target." }
} else {
  gh api --method PUT "repos/$target/pages" -f build_type=workflow | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "GitHub Pages workflow mode could not be verified for $target." }
}

$pages = gh api "repos/$target/pages" | ConvertFrom-Json
if (-not $pages.html_url) { throw "GitHub Pages did not return a review URL for $target." }
if ($pages.build_type -ne 'workflow') { throw "GitHub Pages is not configured for GitHub Actions on $target." }

$deployment = [pscustomobject]@{
  project = $repo
  repository = $target
  status = 'DEPLOYED'
  url = $pages.html_url
  pages_build_type = $pages.build_type
}
$deployment | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $PSScriptRoot '.deployment-result.json')
Write-Host "Repository updated: $target" -ForegroundColor Green
Write-Host "Review URL: $($pages.html_url)" -ForegroundColor Green
