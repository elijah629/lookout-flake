#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NIX="${ROOT}/package.nix"

cd "$ROOT"

set_hash() {
  local name="$1"
  local value="$2"

  NAME="$name" VALUE="$value" perl -0pi -e '
    my $name = $ENV{"NAME"};
    my $value = $ENV{"VALUE"};
    s/\Q$name\E = (?:"[^"]+"|lib\.fakeHash);/$name = $value;/g;
  ' "$PACKAGE_NIX"
}

prefetch_hash() {
  local name="$1"
  local attr="$2"
  local output
  local status
  local hash

  set_hash "$name" "lib.fakeHash"

  set +e
  output="$(nix build ".#${attr}" --no-link --print-build-logs 2>&1)"
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    echo "nix build unexpectedly succeeded while ${name} was lib.fakeHash" >&2
    exit 1
  fi

  hash="$(printf '%s\n' "$output" | sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+\/=]*\).*/\1/p' | tail -n 1)"
  if [ -z "$hash" ]; then
    printf '%s\n' "$output" >&2
    echo "Could not find expected hash for ${name}" >&2
    exit 1
  fi

  set_hash "$name" "\"${hash}\""
  echo "${name}: ${hash}"
}

nix flake update lookout-src

prefetch_hash npmDepsHash lookout-npm-deps
prefetch_hash cargoHash lookout-cargo-deps

nix build .#lookout --no-link --print-build-logs

echo
echo "Updated Lookout source lock and dependency hashes."
