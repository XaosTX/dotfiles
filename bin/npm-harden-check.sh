#!/usr/bin/env bash
# npm-harden-check.sh — verify/restore npm supply-chain hardening.
# Run after every `asdf install nodejs <ver>`: the per-version global npmrc
# does NOT carry across node upgrades.
#
# Usage:  bash ~/bin/npm-harden-check.sh [--fix]
set -uo pipefail

FIX=0
[ "${1:-}" = "--fix" ] && FIX=1
COOLDOWN_DAYS=7          # UNIT IS DAYS on npm 12.x. Not minutes.
MIN_NPM_MAJOR=12
fail=0

ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "npm hardening check — $(date '+%Y-%m-%d %H:%M')"

# --- npm version supports min-release-age ---------------------------------
npmv=$(npm -v 2>/dev/null)
major=${npmv%%.*}
if [ "${major:-0}" -ge "$MIN_NPM_MAJOR" ]; then
  ok "npm $npmv (>= $MIN_NPM_MAJOR, supports min-release-age)"
else
  bad "npm $npmv is older than $MIN_NPM_MAJOR — cooldown is SILENTLY IGNORED"
  [ $FIX -eq 1 ] && { echo "  -> installing npm@$MIN_NPM_MAJOR"; npm install -g "npm@^$MIN_NPM_MAJOR"; asdf reshim nodejs 2>/dev/null; }
fi

# --- effective cooldown ----------------------------------------------------
eff=$(npm config get min-release-age 2>/dev/null)
if [ "$eff" = "$COOLDOWN_DAYS" ]; then
  ok "min-release-age=$eff days"
else
  bad "min-release-age=$eff (expected $COOLDOWN_DAYS)"
  [ $FIX -eq 1 ] && { npm config set min-release-age "$COOLDOWN_DAYS" --location=user; echo "  -> set to $COOLDOWN_DAYS"; }
fi

# A value in the thousands means someone "converted to minutes" — that
# resolves to a date in the 1990s and breaks every install.
case "$eff" in ''|*[!0-9]*) ;; *) [ "$eff" -gt 365 ] && bad "min-release-age=$eff looks like MINUTES; unit is DAYS — installs will fail with ENOVERSIONS";; esac

# --- per-node-version global npmrc (lost on node upgrade) -----------------
g=$(npm config get globalconfig 2>/dev/null)
if [ -f "$g" ] && grep -q "min-release-age=$COOLDOWN_DAYS" "$g" 2>/dev/null; then
  ok "global npmrc present: $g"
else
  bad "global npmrc missing/stale: $g  (expected after a node upgrade)"
  if [ $FIX -eq 1 ]; then
    mkdir -p "$(dirname "$g")"
    printf '# restored by npm-harden-check.sh\n# UNIT IS DAYS, not minutes.\nmin-release-age=%s\nmin-release-age-exclude=\naudit=true\naudit-level=moderate\n' "$COOLDOWN_DAYS" > "$g"
    echo "  -> rewrote $g"
  fi
fi

# --- user npmrc ------------------------------------------------------------
[ -f "$HOME/.npmrc" ] && ok "user npmrc present: ~/.npmrc" || bad "~/.npmrc missing"

# --- other settings --------------------------------------------------------
for kv in "engine-strict=true" "audit=true" "save-exact=true"; do
  k=${kv%%=*}; want=${kv##*=}
  got=$(npm config get "$k" 2>/dev/null)
  [ "$got" = "$want" ] && ok "$k=$got" || { bad "$k=$got (expected $want)"; [ $FIX -eq 1 ] && npm config set "$k" "$want" --location=user; }
done

echo
if [ $fail -eq 0 ]; then
  echo "PASS — hardening intact."
else
  echo "ISSUES FOUND. Re-run with --fix to repair:  bash ~/bin/npm-harden-check.sh --fix"
fi
exit $fail
