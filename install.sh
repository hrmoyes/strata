#!/usr/bin/env bash
# Install Strata into a project. Safe to rerun.
#   ./install.sh /path/to/project                  # local mode (default)
#   ./install.sh /path/to/project --mode shared    # artifacts committed with the code
#   ./install.sh /path/to/project --force          # also replace an outdated STRATA.md
# Without --mode, a rerun keeps the project's current mode (local if none is set).
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$KIT/template"
MARK='<!-- strata:contract'
TARGET="${1:?usage: install.sh <project-dir> [--mode local|shared] [--force]}"
shift
FORCE=""
MODE=""
while (($#)); do
  case "$1" in
    --force) FORCE=1 ;;
    --mode) MODE="${2:?--mode needs local or shared}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
[[ -z "$MODE" || "$MODE" == local || "$MODE" == shared ]] || { echo "--mode must be local or shared" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "Target folder not found: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
say() { echo "  $*"; }
refuse() { { echo "Strata: $*"; echo 'Nothing was changed.'; } >&2; exit 1; }

gi="$TARGET/.gitignore"
installed=0
[[ -f "$gi" ]] && grep -q '^# strata:begin (mode: ' "$gi" && installed=1

# 0. Never take over a STRATA.md or strata/ that Strata didn't create (not even with --force).
if [[ -f "$TARGET/STRATA.md" ]] && ! head -1 "$TARGET/STRATA.md" | grep -qF "$MARK"; then
  refuse 'STRATA.md already exists and was not created by Strata. Rename or remove it first.'
fi
if [[ -e "$TARGET/strata" && ! -f "$TARGET/STRATA.md" && "$installed" == 0 ]]; then
  refuse 'a strata/ folder already exists and was not created by Strata. Rename or remove it first.'
fi

echo "Installing Strata into $TARGET"

# 1. STRATA.md
same() { cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
if [[ ! -f "$TARGET/STRATA.md" ]]; then
  cp "$TPL/STRATA.md" "$TARGET/STRATA.md"; say 'STRATA.md written'
elif same "$TPL/STRATA.md" "$TARGET/STRATA.md"; then
  say 'STRATA.md up to date'
elif [[ -n "$FORCE" ]]; then
  cp "$TPL/STRATA.md" "$TARGET/STRATA.md"; say 'STRATA.md replaced with this Strata version (reapply any workflow settings, e.g. branch name)'
else
  say 'NOTE: STRATA.md differs from this Strata version and was kept.'
  say '      Rerun with --force to update it, then reapply any workflow settings (e.g. branch name).'
fi

# 2. CLAUDE.md (and AGENTS.md if present): insert or refresh the managed block
files=(CLAUDE.md)
[[ -f "$TARGET/AGENTS.md" ]] && files+=(AGENTS.md)
for f in "${files[@]}"; do
  p="$TARGET/$f"
  if [[ ! -f "$p" ]]; then
    { printf '# Project instructions\n\n'; cat "$TPL/CLAUDE-block.md"; } > "$p"
    say "$f created"
  elif grep -q '<!-- strata:begin' "$p"; then
    awk -v blk="$TPL/CLAUDE-block.md" '
      /<!-- strata:begin/ { while ((getline l < blk) > 0) print l; skip=1; next }
      /<!-- strata:end -->/ { skip=0; next }
      !skip' "$p" > "$p.tmp" && mv "$p.tmp" "$p"
    say "$f block refreshed"
  else
    awk -v blk="$TPL/CLAUDE-block.md" '
      NR==1 && /^# / { print; print ""; while ((getline l < blk) > 0) print l; print ""; next }
      NR==1 { while ((getline l < blk) > 0) print l; print "" }
      { print }' "$p" > "$p.tmp" && mv "$p.tmp" "$p"
    say "$f block added"
  fi
done

# 3. .gitignore: managed block that records the mode (local unless chosen otherwise)
touch "$gi"
current="$(sed -nE 's/^# strata:begin \(mode: (local|shared)\).*/\1/p' "$gi" | head -1)"
[[ -n "$MODE" ]] || MODE="${current:-local}"
tr -d '\r' < "$gi" | awk '
  /^# strata:begin \(mode: / { skip=1; next }
  skip && /^# strata:end/ { skip=0; next }
  skip { next }
  /^[ \t]*$/ { blanks++; next }
  { while (blanks > 0) { print ""; blanks-- } print }' > "$gi.tmp"
{
  if [[ -s "$gi.tmp" ]]; then cat "$gi.tmp"; echo; fi
  echo "# strata:begin (mode: $MODE)"
  if [[ "$MODE" == shared ]]; then
    echo '# Artifacts are committed with the code; evidence, externals and scratch stay local. See STRATA.md.'
    echo '/strata/context/*'
    echo '!/strata/context/artifacts/'
  else
    echo '# Agent working memory (see STRATA.md). Never committed.'
    echo '/strata/context/'
  fi
  echo '# strata:end'
} > "$gi" && rm -f "$gi.tmp"
if [[ "$current" == "$MODE" ]]; then say ".gitignore: mode $MODE (unchanged)"
elif [[ -n "$current" ]]; then say ".gitignore: mode switched $current -> $MODE"
else say ".gitignore: mode $MODE"; fi

# 4. strata/context/ and strata/docs/INDEX.md
mkdir -p "$TARGET/strata/context/artifacts" "$TARGET/strata/context/evidence" "$TARGET/strata/docs"
say 'strata/context/artifacts/ and strata/context/evidence/ ready'
if [[ -f "$TARGET/strata/docs/INDEX.md" ]]; then
  say 'strata/docs/INDEX.md exists, kept'
else
  cp "$TPL/strata/docs/INDEX.md" "$TARGET/strata/docs/INDEX.md"
  say 'strata/docs/INDEX.md created'
fi

# 5. pre-commit hook (git repos only; never clobbers someone else's hook)
is_repo=0
git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 && is_repo=1
if [[ "$is_repo" == 0 ]]; then
  say 'not a git repo: hook skipped (rerun after git init)'
elif hp="$(git -C "$TARGET" config --get core.hooksPath)"; then
  say "core.hooksPath is set ($hp): add hooks/pre-commit from Strata to your hook manager by hand"
else
  hookdir="$(cd "$TARGET" && git rev-parse --path-format=absolute --git-path hooks)"
  hook="$hookdir/pre-commit"
  if [[ -f "$hook" ]] && ! grep -q '^# strata: keep' "$hook"; then
    say 'a different pre-commit hook exists: not replaced. Merge hooks/pre-commit into it by hand'
  else
    mkdir -p "$hookdir" && tr -d '\r' < "$KIT/hooks/pre-commit" > "$hook" && chmod +x "$hook"
    say 'pre-commit hook installed'
  fi
fi

if [[ "$MODE" == local && "$is_repo" == 1 && -n "$(git -C "$TARGET" ls-files -- strata/context/)" ]]; then
  say 'NOTE: git still tracks files under strata/context/ (left over from shared mode).'
  say 'Stop tracking them (the files stay on disk), then commit:'
  say '  git rm -r --cached strata/context/'
fi

if [[ "$MODE" == shared ]]; then
  echo 'Done (shared). Commit STRATA.md, CLAUDE.md, .gitignore and strata/docs/; strata/context/artifacts/ is committed with your work, the rest of strata/context/ stays local.'
else
  echo 'Done (local). Commit STRATA.md, CLAUDE.md, .gitignore and strata/docs/; strata/context/ stays local.'
fi
