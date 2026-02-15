#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <semver> [--notes-file <path>|--notes <text>|--generate-notes]" >&2
  exit 1
fi

VERSION="$1"
shift
TAG="v$VERSION"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must match MAJOR.MINOR.PATCH, got '$VERSION'" >&2
  exit 1
fi

ASSET_DIR="$PROJECT_ROOT/dist/releases"
ASSETS=(
  "$ASSET_DIR/zepball.zip"
  "$ASSET_DIR/zepball.x86_64.zip"
  "$ASSET_DIR/SHA256SUMS.txt"
  "$ASSET_DIR/SHA256SUMS.txt.minisig"
  "$ASSET_DIR/minisign.pub"
)

for asset in "${ASSETS[@]}"; do
  if [[ ! -f "$asset" ]]; then
    echo "error: missing release asset: $asset" >&2
    echo "hint: run scripts/export_release_bundle.sh first (with Minisign env vars)." >&2
    exit 1
  fi
done

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not found in PATH" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh CLI is not authenticated (run: gh auth login)" >&2
  exit 1
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "Tag already exists locally: $TAG"
else
  git tag -a "$TAG" -m "Release $TAG"
  echo "Created local tag: $TAG"
fi

git push origin "$TAG"
echo "Pushed tag: $TAG"

if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
  echo "Updated existing release assets for $TAG"
  exit 0
fi

if [[ $# -eq 0 ]]; then
  gh release create "$TAG" "${ASSETS[@]}" --title "$TAG" --generate-notes
  echo "Created release: $TAG (with generated notes)"
  exit 0
fi

gh release create "$TAG" "${ASSETS[@]}" --title "$TAG" "$@"
echo "Created release: $TAG"
