#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRESETS_FILE="$PROJECT_ROOT/export_presets.cfg"
README_FILE="$PROJECT_ROOT/README.md"
LICENSE_FILE="$PROJECT_ROOT/LICENSE"

GODOT_BIN="${GODOT_BIN:-godot}"
MINISIGN_BIN="${MINISIGN_BIN:-minisign}"
MINISIGN_SECRET_KEY="${MINISIGN_SECRET_KEY:-}"
MINISIGN_PUBLIC_KEY="${MINISIGN_PUBLIC_KEY:-}"
RELEASES_DIR="$PROJECT_ROOT/dist/releases"
STAGING_DIR="$RELEASES_DIR/.staging"

if [[ ! -f "$PRESETS_FILE" ]]; then
  echo "error: missing export presets at $PRESETS_FILE" >&2
  exit 1
fi

if [[ ! -f "$README_FILE" ]]; then
  echo "error: missing README at $README_FILE" >&2
  exit 1
fi

if [[ ! -f "$LICENSE_FILE" ]]; then
  echo "error: missing LICENSE at $LICENSE_FILE" >&2
  exit 1
fi

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "error: godot binary not found: $GODOT_BIN" >&2
  exit 1
fi

mapfile -t PRESET_ROWS < <(python3 - "$PRESETS_FILE" <<'PY'
import re
import sys
from pathlib import Path

presets_path = Path(sys.argv[1])
lines = presets_path.read_text(encoding="utf-8").splitlines()
presets: dict[int, dict[str, str]] = {}
active_index: int | None = None

for raw_line in lines:
    line = raw_line.strip()
    header_match = re.match(r"\[preset\.(\d+)\]$", line)
    if header_match:
        active_index = int(header_match.group(1))
        presets.setdefault(active_index, {})
        continue

    if re.match(r"\[preset\.\d+\.options\]$", line):
        active_index = None
        continue

    if active_index is None or "=" not in line:
        continue

    key, value = line.split("=", 1)
    key = key.strip()
    value = value.strip()
    if value.startswith('"') and value.endswith('"'):
        value = value[1:-1]
    presets[active_index][key] = value

for index in sorted(presets.keys()):
    preset = presets[index]
    name = preset.get("name", "").strip()
    export_path = preset.get("export_path", "").strip()
    if not name or not export_path:
        continue
    print(f"{name}\t{export_path}")
PY
)

if [[ ${#PRESET_ROWS[@]} -eq 0 ]]; then
  echo "error: no export presets with name + export_path found" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p "$RELEASES_DIR"

declare -a CREATED_ZIPS=()

for row in "${PRESET_ROWS[@]}"; do
  IFS=$'\t' read -r PRESET_NAME EXPORT_PATH <<< "$row"

  RESOLVED_EXPORT_PATH="$(python3 - "$PROJECT_ROOT" "$EXPORT_PATH" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
export_path = Path(sys.argv[2])
if export_path.is_absolute():
    print(str(export_path))
else:
    print(str((root / export_path).resolve()))
PY
)"

  mkdir -p "$(dirname "$RESOLVED_EXPORT_PATH")"

  echo "Exporting preset: $PRESET_NAME"
  "$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "$PRESET_NAME" "$RESOLVED_EXPORT_PATH"

  PRESET_SLUG="$(python3 - "$PRESET_NAME" <<'PY'
import re
import sys

name = sys.argv[1].strip().lower()
name = re.sub(r"[^a-z0-9]+", "-", name).strip("-")
print(name or "preset")
PY
)"

  PRESET_STAGE_DIR="$STAGING_DIR/$PRESET_SLUG"
  mkdir -p "$PRESET_STAGE_DIR"

  cp "$README_FILE" "$PRESET_STAGE_DIR/README.md"
  cp "$LICENSE_FILE" "$PRESET_STAGE_DIR/LICENSE"
  cp "$RESOLVED_EXPORT_PATH" "$PRESET_STAGE_DIR/"

  EXPORT_DIR="$(dirname "$RESOLVED_EXPORT_PATH")"
  EXPORT_BASE="$(basename "$RESOLVED_EXPORT_PATH")"
  EXPORT_STEM="${EXPORT_BASE%.*}"
  PCK_PATH="$EXPORT_DIR/$EXPORT_STEM.pck"

  if [[ -f "$PCK_PATH" ]]; then
    cp "$PCK_PATH" "$PRESET_STAGE_DIR/"
  fi

  ZIP_NAME=""
  if [[ "$EXPORT_BASE" == *.exe ]]; then
    ZIP_NAME="$EXPORT_STEM.zip"
  else
    ZIP_NAME="$EXPORT_BASE.zip"
  fi

  ZIP_OUTPUT="$RELEASES_DIR/$ZIP_NAME"
  python3 - "$PRESET_STAGE_DIR" "$ZIP_OUTPUT" <<'PY'
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

stage_dir = Path(sys.argv[1])
zip_output = Path(sys.argv[2])

with ZipFile(zip_output, "w", compression=ZIP_DEFLATED) as zf:
    for path in stage_dir.rglob("*"):
        if path.is_file():
            zf.write(path, path.relative_to(stage_dir))
PY

  echo "Created: $ZIP_OUTPUT"
  CREATED_ZIPS+=("$ZIP_OUTPUT")
done

CHECKSUMS_FILE="$RELEASES_DIR/SHA256SUMS.txt"
if [[ ${#CREATED_ZIPS[@]} -gt 0 ]]; then
  # Write checksums using artifact filenames (not absolute paths) for portable release verification.
  mapfile -t ZIP_BASENAMES < <(
    for zip_path in "${CREATED_ZIPS[@]}"; do
      basename "$zip_path"
    done | sort
  )
  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$RELEASES_DIR"
      sha256sum "${ZIP_BASENAMES[@]}"
    ) > "$CHECKSUMS_FILE"
  elif command -v shasum >/dev/null 2>&1; then
    (
      cd "$RELEASES_DIR"
      shasum -a 256 "${ZIP_BASENAMES[@]}"
    ) > "$CHECKSUMS_FILE"
  else
    echo "error: neither sha256sum nor shasum is available for checksum generation" >&2
    exit 1
  fi
  echo "Created: $CHECKSUMS_FILE"

  # Optional: sign checksums file with Minisign when key is provided.
  # Example:
  #   MINISIGN_SECRET_KEY=/path/to/minisign.key \
  #   MINISIGN_PUBLIC_KEY=/path/to/minisign.pub \
  #   ./scripts/export_release_bundle.sh
  if [[ -n "$MINISIGN_SECRET_KEY" ]]; then
    if ! command -v "$MINISIGN_BIN" >/dev/null 2>&1; then
      echo "error: minisign binary not found: $MINISIGN_BIN" >&2
      exit 1
    fi
    if [[ ! -f "$MINISIGN_SECRET_KEY" ]]; then
      echo "error: Minisign secret key not found: $MINISIGN_SECRET_KEY" >&2
      exit 1
    fi

    MINISIG_FILE="$RELEASES_DIR/SHA256SUMS.txt.minisig"
    "$MINISIGN_BIN" -S -s "$MINISIGN_SECRET_KEY" -m "$CHECKSUMS_FILE" -x "$MINISIG_FILE"
    echo "Created: $MINISIG_FILE"

    if [[ -n "$MINISIGN_PUBLIC_KEY" ]]; then
      if [[ ! -f "$MINISIGN_PUBLIC_KEY" ]]; then
        echo "error: Minisign public key not found: $MINISIGN_PUBLIC_KEY" >&2
        exit 1
      fi
      cp "$MINISIGN_PUBLIC_KEY" "$RELEASES_DIR/minisign.pub"
      echo "Created: $RELEASES_DIR/minisign.pub"
    fi
  fi
fi

echo ""
echo "Done."
echo "Staging folder: $STAGING_DIR"
echo "Release zips: $RELEASES_DIR"
