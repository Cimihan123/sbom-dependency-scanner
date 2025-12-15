#!/usr/bin/env bash

export ORG="Cimihan123"
export OUT_DIR="sboms"
export LOG_FILE="sbom-errors.log"

mkdir -p "$OUT_DIR"

usage() {
  echo "Usage:"
  echo "  $0 download              Download SBOMs for all repos"
  echo "  $0 search <package>      Search package in downloaded SBOMs"
  exit 1
}

download_sboms() {
  : > "$LOG_FILE"

  gh repo list "$ORG" --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' |
  while read -r repo; do
    echo "[+] Processing $repo"

    response=$(gh api \
      -H "Accept: application/vnd.github+json" \
      "/repos/$repo/dependency-graph/sbom" 2>>"$LOG_FILE")

    if [ -z "$response" ]; then
      echo "[!] No SBOM returned for $repo" | tee -a "$LOG_FILE"
      continue
    fi

    if ! echo "$response" | jq -e '.sbom.packages | length > 0' >/dev/null 2>&1; then
      echo "[!] No packages found in SBOM for $repo" | tee -a "$LOG_FILE"
      continue
    fi

    echo "$response" | jq '
      .sbom.packages[]
      | select(.name and .SPDXID and .versionInfo)
      | {
          repo: "'"$repo"'",
          name: .name,
          SPDXID: .SPDXID,
          versionInfo: .versionInfo
        }
    ' > "$OUT_DIR/$(echo "$repo" | tr '/' '_').json"
  done

  echo "SBOM download complete"
  echo "Errors logged to $LOG_FILE"
}

search_package() {
  pkg="$1"

  if [ -z "$pkg" ]; then
    echo "Package name required"
    usage
  fi

  if [ ! -d "$OUT_DIR" ] || [ -z "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
    echo "No SBOMs found."
    echo "Please run: $0 download"
    exit 1
  fi

  echo "Searching for package: $pkg"
  echo

  found=false

  for file in "$OUT_DIR"/*.json; do
    if jq -e --arg pkg "$pkg" '
      select(.name == $pkg)
    ' "$file" >/dev/null; then

      jq -r --arg pkg "$pkg" '
        select(.name == $pkg)
        | "Repo: \(.repo)\n  Package: \(.name)\n  Version: \(.versionInfo)\n"
      ' "$file"

      found=true
    fi
  done

  if [ "$found" = false ]; then
    echo "Package not found in downloaded SBOMs."
  fi
}

case "$1" in
  download)
    download_sboms
    ;;
  search)
    search_package "$2"
    ;;
  *)
    usage
    ;;
esac


