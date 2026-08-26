param([string]$Owner="",[switch]$SkipBuild)
$ErrorActionPreference="Stop"
Set-Location $PSScriptRoot
if(-not $SkipBuild){& ./BUILD.ps1;& ./QA.ps1}
foreach($c in @('git','gh')){if(-not(Get-Command $c -ErrorAction SilentlyContinue)){throw "Required command not found: $c"}}
gh auth status;if($LASTEXITCODE-ne 0){throw 'GitHub authentication is required. Run gh auth login.'}
if(-not $Owner){$Owner=(gh api user --jq .login).Trim()}
$repo=Split-Path $PSScriptRoot -Leaf;$target="$Owner/$repo"
if(-not(Test-Path .git)){git init;git branch -M main}
$remote=git remote get-url origin 2>$null;if($remote){$m=[regex]::Match($remote,'github\.com[:/](?<slug>[^/]+/[^/.]+)');if($m.Success){$target=$m.Groups['slug'].Value}}
gh repo view $target --json nameWithOwner 2>$null|Out-Null;$exists=$LASTEXITCODE-eq 0
if(-not $exists){gh repo create $target --public --source . --remote origin;if($LASTEXITCODE-ne 0){throw "Repository creation failed: $target"}}elseif(-not(git remote get-url origin 2>$null)){git remote add origin "https://github.com/$target.git"}
if(-not(git config user.name)){git config user.name $Owner};if(-not(git config user.email)){git config user.email "$Owner@users.noreply.github.com"}
git add .;git diff --cached --quiet;if($LASTEXITCODE-ne 0){git commit -m 'Production review upgrade';if($LASTEXITCODE-ne 0){throw 'Git commit failed.'}}
git fetch origin main 2>$null;if($LASTEXITCODE-eq 0){git merge-base --is-ancestor origin/main HEAD 2>$null;if($LASTEXITCODE-ne 0){git merge origin/main --allow-unrelated-histories -s ours -m 'Preserve remote history for production upgrade';if($LASTEXITCODE-ne 0){throw 'Remote history merge failed.'}}}
git push -u origin main;if($LASTEXITCODE-ne 0){throw "Push failed: $target"}
gh api "repos/$target/pages" 2>$null|Out-Null;if($LASTEXITCODE-ne 0){gh api --method POST "repos/$target/pages" -f build_type=workflow|Out-Null}else{gh api --method PUT "repos/$target/pages" -f build_type=workflow|Out-Null};if($LASTEXITCODE-ne 0){throw 'GitHub Pages configuration failed.'}
$pages=gh api "repos/$target/pages"|ConvertFrom-Json;if(-not $pages.html_url){throw 'GitHub Pages did not return a URL.'}
[pscustomobject]@{project=$repo;repository=$target;status='DEPLOYED';url=$pages.html_url}|ConvertTo-Json|Set-Content -Encoding utf8 .deployment-result.json
Write-Host "Review URL: $($pages.html_url)" -ForegroundColor Green
