#!/usr/bin/env bash
# Deploy this repo into the Herdr app home.
#
#   ./scripts/install.sh              mods + layout
#   ./scripts/install.sh --keys       also keys.json
#   ./scripts/install.sh --settings   also settings.json (drops live zoom)
#   ./scripts/install.sh --dry-run    say what would change
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_HOME="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
export HERDR_APP_HOME="$APP_HOME"

KEYS=0; SETTINGS=0; DRY=0
for a in "$@"; do
  case "$a" in
    --keys) KEYS=1 ;;
    --settings) SETTINGS=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ -d "$APP_HOME" ] || { echo "no app home at $APP_HOME" >&2; exit 1; }
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$APP_HOME/backups/herdr-config-$STAMP"

# Keep the backup folder from growing a full copy per run: only the last three.
if [ "$DRY" -eq 0 ] && [ -d "$APP_HOME/backups" ]; then
  ls -1dt "$APP_HOME"/backups/herdr-config-* 2>/dev/null | tail -n +3 | while read -r old; do
    rm -rf "$old"
  done
fi

say() { printf '%s\n' "$*"; }
run() { [ "$DRY" -eq 1 ] && say "would: $*" || "$@"; }

# Back a live path up once, before it is replaced.
save() {
  local target="$1"
  [ -e "$target" ] || return 0
  local rel="${target#"$APP_HOME"/}"
  [ "$DRY" -eq 1 ] && { say "would back up: $rel"; return 0; }
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -R "$target" "$BACKUP/$rel"
}

# ── mods ──────────────────────────────────────────────────────────────────────
say "== mods"
for dir in "$ROOT"/mods/*/; do
  name="$(basename "$dir")"
  dest="$APP_HOME/mods/$name"
  save "$dest"
  run rm -rf "$dest"
  run mkdir -p "$dest"
  run cp -R "$dir." "$dest/"
  say "  $name"
done

# ── overrides ────────────────────────────────────────────────────────────────
for dir in "$ROOT"/overrides/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  dest="$APP_HOME/mods/$name"
  [ -d "$dest" ] || { echo "override for missing mod: $name" >&2; exit 1; }
  say "== override: $name"
  run cp -R "$dir." "$dest/"
done

# ── layout ───────────────────────────────────────────────────────────────────
say "== layout"
save "$APP_HOME/layouts/OBINNA.json"
run mkdir -p "$APP_HOME/layouts"
run cp "$ROOT/layouts/OBINNA.json" "$APP_HOME/layouts/OBINNA.json"

# ── optional config ──────────────────────────────────────────────────────────
if [ "$KEYS" -eq 1 ]; then
  say "== keys.json"
  save "$APP_HOME/keys.json"
  run cp "$ROOT/keys.json" "$APP_HOME/keys.json"
fi
if [ "$SETTINGS" -eq 1 ]; then
  say "== settings.json (zoom reset)"
  save "$APP_HOME/settings.json"
  run cp "$ROOT/settings.json" "$APP_HOME/settings.json"
fi

[ "$DRY" -eq 1 ] && { say "dry run: nothing changed"; exit 0; }
[ -d "$BACKUP" ] && say "backups: $BACKUP"

# ── gates ────────────────────────────────────────────────────────────────────
say "== herdr-app check"
fail=0
for dir in "$ROOT"/mods/*/; do
  name="$(basename "$dir")"
  if herdr-app check "$APP_HOME/mods/$name" >/dev/null 2>&1; then
    say "  ok    $name"
  else
    say "  FAIL  $name"
    herdr-app check "$APP_HOME/mods/$name" 2>&1 | tail -5 | sed 's/^/        /'
    fail=1
  fi
done

say "== herdr-app status"
status="$(herdr-app status 2>&1)"
printf '%s\n' "$status" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print('  (unreadable status)'); sys.exit(1)
errs=d.get('errors') or []
print('  errors:', errs)
print('  layout:', d.get('layout'))
sys.exit(1 if errs else 0)
" || fail=1

[ "$fail" -eq 0 ] && say "done" || { say "FAILED" >&2; exit 1; }
