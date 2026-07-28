#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Kullanım: $0 <imzasız-app.zip> <profil.mobileprovision> <cihaz-id> [çıktı.ipa]" >&2
  exit 64
fi

archive_path=$1
profile_path=$2
device_id=$3
output_ipa=${4:-"$PWD/Masalci-device.ipa"}
signing_identity=${MASALCI_SIGNING_IDENTITY:-"Apple Development: Emre Isik (7354WYZKF5)"}
repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
requested_entitlements_path=${MASALCI_APP_ENTITLEMENTS_PATH:-"$repository_root/Targets/App/Resources/Masalci.entitlements"}

if [[ ! -f "$archive_path" ]]; then
  echo "İmzasız uygulama arşivi bulunamadı: $archive_path" >&2
  exit 66
fi

if [[ ! -f "$profile_path" ]]; then
  echo "Provisioning profile bulunamadı: $profile_path" >&2
  exit 66
fi

for required_tool in codesign ditto plutil ruby security xcrun; do
  if ! command -v "$required_tool" >/dev/null 2>&1; then
    echo "Gerekli araç bulunamadı: $required_tool" >&2
    exit 69
  fi
done

if ! security find-identity -v -p codesigning | grep -Fq "$signing_identity"; then
  echo "Geçerli imzalama kimliği bulunamadı: $signing_identity" >&2
  exit 69
fi

temp_parent=${MASALCI_SIGNING_TEMP_ROOT:-${TMPDIR:-/tmp}}
mkdir -p "$temp_parent"
working_dir=$(mktemp -d "$temp_parent/masalci-sign.XXXXXX")

cleanup() {
  rm -rf "$working_dir"
}
trap cleanup EXIT

ditto -x -k "$archive_path" "$working_dir/unpacked"

app_count=$(find "$working_dir/unpacked" -maxdepth 1 -type d -name '*.app' | wc -l | tr -d ' ')
if [[ "$app_count" != "1" ]]; then
  echo "Arşivde beklenen tek .app paketi bulunamadı." >&2
  exit 65
fi
app_path=$(find "$working_dir/unpacked" -maxdepth 1 -type d -name '*.app' -print -quit)

decoded_profile="$working_dir/profile.plist"
entitlements_path="$working_dir/entitlements.plist"
security cms -D -i "$profile_path" > "$decoded_profile"

bundle_identifier=$(plutil -extract CFBundleIdentifier raw -o - "$app_path/Info.plist")
application_identifier=$(plutil -extract Entitlements.application-identifier raw -o - "$decoded_profile")
team_identifier=$(plutil -extract TeamIdentifier.0 raw -o - "$decoded_profile")

if [[ "$application_identifier" != "$team_identifier.$bundle_identifier" && "$application_identifier" != "$team_identifier.*" ]]; then
  echo "Provisioning profile uygulama kimliğiyle eşleşmiyor: $bundle_identifier" >&2
  exit 65
fi

"$repository_root/scripts/prepare-signing-entitlements.sh" \
  "$decoded_profile" \
  "$requested_entitlements_path" \
  "$bundle_identifier" \
  "$entitlements_path"

cp "$profile_path" "$app_path/embedded.mobileprovision"

while IFS= read -r -d '' dylib_path; do
  codesign --force --sign "$signing_identity" --timestamp=none "$dylib_path"
done < <(find "$app_path" -type f -name '*.dylib' -print0)

while IFS= read -r -d '' framework_path; do
  codesign --force --sign "$signing_identity" --timestamp=none "$framework_path"
done < <(find "$app_path" -depth -type d -name '*.framework' -print0)

while IFS= read -r -d '' extension_path; do
  codesign --force --sign "$signing_identity" --timestamp=none --entitlements "$entitlements_path" "$extension_path"
done < <(find "$app_path" -depth -type d -name '*.appex' -print0)

codesign \
  --force \
  --sign "$signing_identity" \
  --timestamp=none \
  --entitlements "$entitlements_path" \
  "$app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"

mkdir -p "$working_dir/Payload"
ditto "$app_path" "$working_dir/Payload/$(basename "$app_path")"
mkdir -p "$(dirname "$output_ipa")"
ditto -c -k --sequesterRsrc --keepParent "$working_dir/Payload" "$output_ipa"

xcrun devicectl device install app --device "$device_id" "$app_path"
xcrun devicectl device process launch \
  --device "$device_id" \
  --terminate-existing \
  "$bundle_identifier"

echo "Masalcı kuruldu ve açıldı. IPA: $output_ipa"
