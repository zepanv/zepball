#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

errors=0

error() {
  printf 'ERROR: %s\n' "$1"
  errors=$((errors + 1))
}

check_markdown_links() {
  local file lineno text match raw_target target path dir

  while IFS=: read -r file lineno text; do

    while IFS= read -r match; do
      raw_target="${match#*](}"
      raw_target="${raw_target%)}"
      raw_target="${raw_target%% *}"
      target="${raw_target%\"}"
      target="${target#\"}"

      case "$target" in
        ""|\#*|http://*|https://*|mailto:*|tel:*|javascript:*)
          continue
          ;;
      esac

      path="${target%%#*}"
      if [[ -z "$path" ]]; then
        continue
      fi

      if [[ "$path" == /* ]]; then
        [[ -e "$path" ]] || error "$file:$lineno broken absolute link target: $target"
      else
        dir="$(dirname "$file")"
        [[ -e "$dir/$path" ]] || error "$file:$lineno broken relative link target: $target"
      fi
    done < <(printf '%s\n' "$text" | grep -oE '\[[^][]+\]\([^)]+\)' || true)
  done < <(rg -n --glob '*.md' '\[[^]]+\]\([^)]+\)' .agent)
}

check_forbidden_paths_in_canonical_docs() {
  local files
  files=(
    .agent/AGENTS.md
    .agent/README.md
    .agent/QUICK-REF.md
    .agent/SOP/critical-workflows.md
    .agent/SOP/godot-workflow.md
    .agent/System/architecture.md
    .agent/System/architecture-details.md
    .agent/System/tech-stack.md
  )

  rg -n 'data/level_sets\.json|levels/level_[0-9]{2}\.json|assets/sprites/' "${files[@]}" \
    && error "forbidden legacy path reference found in canonical/supplemental docs" || true
}

check_supplemental_doc_stays_non_canonical() {
  local sop_file=".agent/SOP/godot-workflow.md"

  rg -n '^## (Save System Compatibility|Asset Documentation Requirements|Commit Message Format|Release Versioning)' "$sop_file" \
    && error "$sop_file reintroduced canonical procedure sections" || true
}

check_architecture_split_integrity() {
  rg -n 'architecture-details\.md' .agent/System/architecture.md >/dev/null \
    || error ".agent/System/architecture.md missing link to architecture-details.md"

  [[ -f .agent/System/architecture-details.md ]] \
    || error ".agent/System/architecture-details.md missing"

  [[ -f .agent/Tasks/Completed/INDEX.md ]] \
    || error ".agent/Tasks/Completed/INDEX.md missing"
}

check_architecture_details_stays_lean() {
  local file=".agent/System/architecture-details.md"
  local words

  words="$(wc -w < "$file" | tr -d ' ')"
  if [[ "$words" -gt 1800 ]]; then
    error "$file is too large ($words words); keep deep notes lean and contract-focused"
  fi

  rg -n '^## (Project Structure|Runtime Scene Graph|Input Map|Complete Gameplay Flow|Visual Polish and Assets|Data Persistence)' "$file" \
    && error "$file reintroduced discoverable inventory sections" || true
}

check_archived_task_links_are_direct() {
  local archived_basenames='audio-system|bugfixes-and-pack-ui|core-mechanics|keybinding-menu|level-system|power-up-expansion|power-ups|quick-actions|save-system|settings-enhancements|tile-system|ui-gaps|ui-system'

  rg -n "Tasks/Completed/(${archived_basenames})\\.md" .agent \
    && error "archived task links must point to Tasks/Completed/Archive/*" || true
}

check_headless_command_uses_temp_home() {
  local file=".agent/SOP/godot-workflow.md"
  rg -n 'HOME=/tmp/zepball-godot-home.*--headless.*--quit' "$file" >/dev/null \
    || error "$file must document headless sanity check with temporary HOME override"
}

main() {
  check_markdown_links
  check_forbidden_paths_in_canonical_docs
  check_supplemental_doc_stays_non_canonical
  check_architecture_split_integrity
  check_architecture_details_stays_lean
  check_archived_task_links_are_direct
  check_headless_command_uses_temp_home

  if [[ "$errors" -gt 0 ]]; then
    printf '\n.agent docs lint failed with %d error(s).\n' "$errors"
    exit 1
  fi

  printf '.agent docs lint passed.\n'
}

main "$@"
