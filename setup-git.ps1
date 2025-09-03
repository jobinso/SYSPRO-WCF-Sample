Param(
    [string]$RepoName = "syspro-wcf-sample",
    [string]$Account = "jobinso",
    [ValidateSet("https","ssh")] [string]$Remote = "https",
    [string]$UserName = "James Robinson",
    [string]$UserEmail = "james@greenbits.com.au"
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "✔ $msg" -ForegroundColor Green }
function Fail($msg)       { Write-Error $msg; exit 1 }

# 0) Pre-flight checks
Write-Step "Checking dependencies"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "Git is not installed or not in PATH." }

# 1) Ensure we're in the project folder (warn if suspicious)
Write-Step "Validating current directory contents"
$hasReadme = Test-Path -Path ".\README.md"
$hasSln    = Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $hasReadme -and -not $hasSln) {
    Fail "This doesn't look like the project root (no README.md or .sln found). cd into the unzipped repo folder and try again."
}

# 2) Configure local Git identity
Write-Step "Configuring local git user"
git config user.name  "$UserName"
git config user.email "$UserEmail"
Write-Ok "Git user set to $UserName <$UserEmail>"

# 3) Init repo (if needed)
if (-not (Test-Path ".\.git")) {
    Write-Step "Initializing repository"
    git init | Out-Null
    Write-Ok "Initialized .git"
} else {
    Write-Ok "Git repo already initialized"
}

# 4) Initial add/commit (if none)
$hasCommit = (git rev-parse --verify HEAD 2>$null) -ne $null
if (-not $hasCommit) {
    Write-Step "Staging files"
    git add .
    Write-Step "Creating initial commit"
    git commit -m "Initial commit: SYSPRO WCF sample" | Out-Null
    Write-Ok "Committed"
} else {
    Write-Ok "Existing commits detected; skipping initial commit"
}

# 5) Ensure main branch
Write-Step "Setting default branch to 'main'"
git branch -M main

# 6) Add remote
Write-Step "Configuring remote origin"
$remoteUrl = if ($Remote -eq "ssh") {
    "git@github.com:$Account/$RepoName.git"
} else {
    "https://github.com/$Account/$RepoName.git"
}

# If remote exists, update it; else add it
$existingRemote = (git remote) -contains "origin"
if ($existingRemote) {
    git remote set-url origin $remoteUrl
} else {
    git remote add origin $remoteUrl
}
Write-Ok "Remote origin => $remoteUrl"

# 7) Push
Write-Step "Pushing to GitHub (this may prompt you to authenticate)"
git push -u origin main

Write-Ok "Done! Visit https://github.com/$Account/$RepoName"
