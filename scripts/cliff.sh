#!/usr/bin/env bash

#USAGE flag "--dry-run" help="Print the next version without releasing"

set -euo pipefail

export GIT_CLIFF_CONFIG="$(dirname "${BASH_SOURCE[0]}")/cliff.toml"

function get_ref() {
  TYPE="branch"
  if [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
    TYPE="tag"
  elif git describe --tags --exact-match >/dev/null 2>&1; then
    TYPE="tag"
  fi

  if [ -n "${GITHUB_REF_NAME:-}" ]; then
    echo "$TYPE/$GITHUB_REF_NAME"
  else
    echo "$TYPE/$(git symbolic-ref --quiet --short HEAD || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)"
  fi
}

if git remote get-url origin >/dev/null 2>&1; then
  export GITHUB_TOKEN=${GITHUB_TOKEN:-$(gh auth token)}
  export GITHUB_REPO=$(git remote get-url origin | sed -E 's#(\.git)?/?$##; s#.*[:/]([^:/]+/[^:/]+)$#\1#')
fi

VERSION=$(git cliff --offline --unreleased --bumped-version)
if [ "${usage_dry_run:-false}" = true ]; then
  echo "$VERSION"
  exit 0
fi

# Release branches (main/master) and prerelease branches (alpha/beta/rc/next).
if [[ "$(get_ref)" =~ ^branch/(main|master|alpha|beta|rc|next)$ ]]; then
  CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ "$VERSION" = "$CURRENT" ]; then
    echo "No release-worthy changes since $CURRENT, skipping release."
  else
    git cliff --unreleased --tag "$VERSION" --output CHANGELOG.md
    # gh release create "$VERSION" --title "$VERSION" --target "$(git rev-parse HEAD)" --notes-file CHANGELOG.md
  fi
else
  echo "Not a release or pre-release branch, skipping release."
fi
