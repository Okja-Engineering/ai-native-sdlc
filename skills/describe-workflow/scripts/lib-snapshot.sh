#!/usr/bin/env bash
# Shared snapshot helpers for describe-workflow. Sourced by new-snapshot.sh
# and validate-observation.sh. Provides content-based snapshot identity over
# the inspection scope so dirty working trees and untracked files are covered.

hash_file() { # path -> hex digest
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

hash_stdin() { # -> hex digest of stdin
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# link_entry LINK REPO — manifest line for a symlink. Records the literal
# target plus its disposition:
#   [in-repo]   resolved target is inside the inspected root — its content is
#               covered only if the target path itself falls in scope
#   [external]  resolved target is outside the root — never read
#   [broken]    target does not resolve — recorded, never followed
# Link target content is never hashed through the link: the inspection
# boundary is the declared scope, not whatever a link happens to reach.
link_entry() {
  local l="$1" repo="$2" rel tgt resolved=""
  rel="${l#"$repo"/}"; rel="${rel#./}"
  tgt="$(readlink "$l")" || { printf 'LINK  %s  ->  <unreadable>\n' "$rel"; return; }
  # Resolve the target's parent for classification, tolerating failure — a
  # missing parent must not abort the snapshot. Then require the target
  # itself to exist (-e follows the link): an existing parent with a missing
  # final name is broken, not in-repo.
  resolved="$(cd "$(dirname "$l")" 2>/dev/null \
    && cd "$(dirname "$tgt")" 2>/dev/null \
    && printf '%s/%s' "$(pwd -P)" "$(basename "$tgt")")" || resolved=""
  if [[ -z "$resolved" || ! -e "$l" ]]; then
    printf 'LINK  %s  ->  %s  [broken]\n' "$rel" "$tgt"
  elif [[ "$resolved" == "$repo" || "$resolved" == "$repo"/* ]]; then
    printf 'LINK  %s  ->  %s  [in-repo]\n' "$rel" "$tgt"
  else
    printf 'LINK  %s  ->  %s  [external]\n' "$rel" "$tgt"
  fi
}

# snapshot_manifest REPO_ROOT SCOPE_CSV — one line per inspected entry:
#   "<hash>  <relpath>"   regular file content
#   "LINK  <relpath>  ->  <target>  [in-repo|external|broken]"   symlink
#   "MISSING  <scope-entry>"   declared-but-absent scope entry
# Scope entries are comma-separated paths relative to REPO_ROOT; directories
# expand to all contained entries (excluding .git, never following links).
snapshot_manifest() {
  local repo="$1" scope="$2" e rel
  local OLDIFS="$IFS"; IFS=','
  for e in $scope; do
    IFS="$OLDIFS"
    e="${e#./}"
    if [[ -L "$repo/$e" ]]; then
      link_entry "$repo/$e" "$repo"
    elif [[ -d "$repo/$e" ]]; then
      while IFS= read -r f; do
        rel="${f#"$repo"/}"; rel="${rel#./}"
        printf '%s  %s\n' "$(hash_file "$f")" "$rel"
      done < <(find "$repo/$e" -type f ! -path '*/.git/*' | sort)
      while IFS= read -r l; do
        link_entry "$l" "$repo"
      done < <(find "$repo/$e" -type l | sort)
    elif [[ -f "$repo/$e" ]]; then
      printf '%s  %s\n' "$(hash_file "$repo/$e")" "$e"
    else
      printf 'MISSING  %s\n' "$e"
    fi
    IFS=','
  done
  IFS="$OLDIFS"
}
