#!/usr/bin/env bash

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_directory=$(mktemp -d /tmp/masalci-signing-test.XXXXXX)
output_path="$test_directory/entitlements.plist"

cleanup() {
  rm -rf "$test_directory"
}
trap cleanup EXIT

"$repository_root/scripts/prepare-signing-entitlements.sh" \
  "$repository_root/scripts/test-fixtures/profile-with-legacy-entitlements.plist" \
  "$repository_root/Targets/App/Resources/Masalci.entitlements" \
  "tr.kirke.masalci" \
  "$output_path"

assert_plist_value() {
  local path=$1
  local expected=$2
  local actual
  actual=$(/usr/libexec/PlistBuddy -c "Print :$path" "$output_path")
  if [[ "$actual" != "$expected" ]]; then
    echo "$path için '$expected' bekleniyordu, '$actual' bulundu." >&2
    exit 1
  fi
}

assert_plist_value "application-identifier" "235UP83FJ4.tr.kirke.masalci"
assert_plist_value "com.apple.developer.team-identifier" "235UP83FJ4"
assert_plist_value "com.apple.developer.applesignin:0" "Default"
assert_plist_value "get-task-allow" "true"
assert_plist_value "keychain-access-groups:0" "235UP83FJ4.tr.kirke.masalci"

if /usr/libexec/PlistBuddy -c "Print :aps-environment" "$output_path" >/dev/null 2>&1; then
  echo "İstenmeyen bildirim yetkisi imzaya taşındı." >&2
  exit 1
fi

if /usr/libexec/PlistBuddy -c "Print :com.apple.security.application-groups" "$output_path" >/dev/null 2>&1; then
  echo "İstenmeyen eski uygulama grubu imzaya taşındı." >&2
  exit 1
fi

echo "Cihaz imza yetkileri testi geçti."
