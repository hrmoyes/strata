<#
.SYNOPSIS
  Install Strata into a project. Safe to rerun.

.EXAMPLE
  .\install.ps1 -Target C:\code\my-project                 # local mode (default)
  .\install.ps1 -Target C:\code\my-project -Mode shared    # artifacts committed with the code
  .\install.ps1 -Target . -Force                           # also replace an outdated STRATA.md

  Without -Mode, a rerun keeps the project's current mode (local if none is set).
#>
param(
  [Parameter(Mandatory = $true)][string]$Target,
  [ValidateSet('local', 'shared')][string]$Mode,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$Kit = $PSScriptRoot
$Tpl = Join-Path $Kit 'template'
$Mark = '<!-- strata:contract'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $Target -PathType Container)) { throw "Target folder not found: $Target" }
$Target = (Resolve-Path $Target).Path

function Read-Utf8($Path) { [IO.File]::ReadAllText($Path, $Utf8) }
function Write-Utf8($Path, $Text) {
  $dir = Split-Path $Path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [IO.File]::WriteAllText($Path, $Text, $Utf8)
}
function Say($m) { Write-Host "  $m" }
function Refuse($m) {
  [Console]::Error.WriteLine("Strata: $m")
  [Console]::Error.WriteLine('Nothing was changed.')
  exit 1
}

$gi = Join-Path $Target '.gitignore'
$strataMd = Join-Path $Target 'STRATA.md'
$giText = if (Test-Path $gi) { (Read-Utf8 $gi).Replace("`r`n", "`n") } else { '' }
$installed = $giText -match '(?m)^# strata:begin \(mode: '

# 0. Never take over a STRATA.md or strata/ that Strata didn't create (not even with -Force).
if ((Test-Path $strataMd) -and -not ((Get-Content $strataMd -TotalCount 1) -like "$Mark*")) {
  Refuse 'STRATA.md already exists and was not created by Strata. Rename or remove it first.'
}
if ((Test-Path (Join-Path $Target 'strata')) -and -not (Test-Path $strataMd) -and -not $installed) {
  Refuse 'a strata/ folder already exists and was not created by Strata. Rename or remove it first.'
}

Write-Host "Installing Strata into $Target"

# 1. STRATA.md
$tplText = (Read-Utf8 (Join-Path $Tpl 'STRATA.md')).Replace("`r`n", "`n")
if (-not (Test-Path $strataMd)) {
  Write-Utf8 $strataMd $tplText; Say 'STRATA.md written'
} elseif ((Read-Utf8 $strataMd).Replace("`r`n", "`n") -ceq $tplText) {
  Say 'STRATA.md up to date'
} elseif ($Force) {
  Write-Utf8 $strataMd $tplText; Say 'STRATA.md replaced with this Strata version (reapply any workflow settings, e.g. branch name)'
} else {
  Say 'NOTE: STRATA.md differs from this Strata version and was kept.'
  Say '      Rerun with -Force to update it, then reapply any workflow settings (e.g. branch name).'
}

# 2. CLAUDE.md (and AGENTS.md if the project has one): insert or refresh the managed block
$block = (Read-Utf8 (Join-Path $Tpl 'CLAUDE-block.md')).Replace("`r`n", "`n").TrimEnd()
$pattern = '(?s)<!-- strata:begin.*?<!-- strata:end -->'
$files = @('CLAUDE.md')
if (Test-Path (Join-Path $Target 'AGENTS.md')) { $files += 'AGENTS.md' }
foreach ($f in $files) {
  $p = Join-Path $Target $f
  if (-not (Test-Path $p)) {
    Write-Utf8 $p ("# Project instructions`n`n" + $block + "`n")
    Say "$f created"
  } else {
    $text = Read-Utf8 $p
    if ($text -match $pattern) {
      $text = [regex]::Replace($text, $pattern, { param($m) $block })
      Say "$f block refreshed"
    } else {
      # Put the block first so agents read it before project-specific detail.
      $lines = $text -split "`n", 2
      if ($lines[0] -match '^#\s') {
        $text = $lines[0] + "`n`n" + $block + "`n`n" + ($(if ($lines.Count -gt 1) { $lines[1].TrimStart() } else { '' }))
      } else {
        $text = $block + "`n`n" + $text
      }
      Say "$f block added"
    }
    Write-Utf8 $p $text
  }
}

# 3. .gitignore: managed block that records the mode (local unless chosen otherwise)
$giPattern = '(?s)# strata:begin \(mode: (local|shared)\).*?# strata:end\n?'
$current = if ($giText -match $giPattern) { $Matches[1] } else { $null }
if (-not $Mode) { $Mode = if ($current) { $current } else { 'local' } }
$giBlock = if ($Mode -eq 'shared') {
  "# strata:begin (mode: shared)`n# Artifacts are committed with the code; evidence, externals and scratch stay local. See STRATA.md.`n/strata/context/*`n!/strata/context/artifacts/`n# strata:end`n"
} else {
  "# strata:begin (mode: local)`n# Agent working memory (see STRATA.md). Never committed.`n/strata/context/`n# strata:end`n"
}
$giText = ([regex]::Replace($giText, $giPattern, '')).TrimEnd()
Write-Utf8 $gi ($(if ($giText) { $giText + "`n`n" } else { '' }) + $giBlock)
if ($current -eq $Mode) { Say ".gitignore: mode $Mode (unchanged)" }
elseif ($current) { Say ".gitignore: mode switched $current -> $Mode" }
else { Say ".gitignore: mode $Mode" }

# 4. strata/context/ and strata/docs/INDEX.md
foreach ($d in 'context\artifacts', 'context\evidence', 'docs') { New-Item -ItemType Directory -Force (Join-Path $Target "strata\$d") | Out-Null }
Say 'strata/context/artifacts/ and strata/context/evidence/ ready'
$idx = Join-Path $Target 'strata\docs\INDEX.md'
if (-not (Test-Path $idx)) {
  Write-Utf8 $idx (Read-Utf8 (Join-Path $Tpl 'strata\docs\INDEX.md'))
  Say 'strata/docs/INDEX.md created'
} else {
  Say 'strata/docs/INDEX.md exists, kept'
}

# 5. pre-commit hook (git repos only; never clobbers someone else's hook)
$isRepo = $false
try { git -C $Target rev-parse --git-dir *> $null; $isRepo = ($LASTEXITCODE -eq 0) } catch {}
if (-not $isRepo) {
  Say 'not a git repo: hook skipped (rerun after git init)'
} else {
  $hooksPath = (git -C $Target config --get core.hooksPath) 2>$null
  if ($hooksPath) {
    Say "core.hooksPath is set ($hooksPath): add hooks\pre-commit from Strata to your hook manager by hand"
  } else {
    $hookDir = (git -C $Target rev-parse --path-format=absolute --git-path hooks).Trim()
    $hook = Join-Path $hookDir 'pre-commit'
    $src = (Read-Utf8 (Join-Path $Kit 'hooks\pre-commit')).Replace("`r`n", "`n")
    if ((Test-Path $hook) -and -not ((Read-Utf8 $hook) -match '(?m)^# strata: keep')) {
      Say "a different pre-commit hook exists: not replaced. Merge hooks\pre-commit into it by hand"
    } else {
      Write-Utf8 $hook $src
      Say 'pre-commit hook installed'
    }
  }
}

if ($Mode -eq 'local' -and $isRepo -and (git -C $Target ls-files -- strata/context/)) {
  Say 'NOTE: git still tracks files under strata/context/ (left over from shared mode).'
  Say 'Stop tracking them (the files stay on disk), then commit:'
  Say '  git rm -r --cached strata/context/'
}

if ($Mode -eq 'shared') {
  Write-Host 'Done (shared). Commit STRATA.md, CLAUDE.md, .gitignore and strata/docs/; strata/context/artifacts/ is committed with your work, the rest of strata/context/ stays local.'
} else {
  Write-Host 'Done (local). Commit STRATA.md, CLAUDE.md, .gitignore and strata/docs/; strata/context/ stays local.'
}
exit 0
