#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Kullanım: $0 <profil.plist> <uygulama.entitlements> <bundle-id> <çıktı.plist>" >&2
  exit 64
fi

profile_path=$1
requested_entitlements_path=$2
bundle_identifier=$3
output_path=$4

for required_tool in plutil ruby; do
  if ! command -v "$required_tool" >/dev/null 2>&1; then
    echo "Gerekli araç bulunamadı: $required_tool" >&2
    exit 69
  fi
done

if [[ ! -f "$profile_path" || ! -f "$requested_entitlements_path" ]]; then
  echo "Profil veya uygulama yetki dosyası bulunamadı." >&2
  exit 66
fi

profile_application_identifier=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" "$profile_path")
team_identifier=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" "$profile_path")
expected_application_identifier="$team_identifier.$bundle_identifier"

if [[ "$profile_application_identifier" != "$expected_application_identifier" && "$profile_application_identifier" != "$team_identifier.*" ]]; then
  echo "Provisioning profile uygulama kimliğiyle eşleşmiyor: $bundle_identifier" >&2
  exit 65
fi

while IFS= read -r requested_key; do
  case "$requested_key" in
    com.apple.developer.applesignin) ;;
    *)
      echo "İmzalama aracı tarafından desteklenmeyen uygulama yetkisi: $requested_key" >&2
      exit 65
      ;;
  esac
done < <(
  plutil -convert json -o - "$requested_entitlements_path" |
    ruby -rjson -e 'JSON.parse(STDIN.read).keys.sort.each { |key| puts key }'
)

requested_apple_sign_in=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.applesignin:0" "$requested_entitlements_path" 2>/dev/null || true)
profile_apple_sign_in=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.applesignin:0" "$profile_path" 2>/dev/null || true)
if [[ -n "$requested_apple_sign_in" && "$requested_apple_sign_in" != "$profile_apple_sign_in" ]]; then
  echo "Provisioning profile Apple ile Giriş yetkisini karşılamıyor." >&2
  exit 65
fi

cp "$requested_entitlements_path" "$output_path"
/usr/libexec/PlistBuddy -c "Add :application-identifier string $expected_application_identifier" "$output_path"
/usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team_identifier" "$output_path"

get_task_allow=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:get-task-allow" "$profile_path" 2>/dev/null || true)
if [[ -n "$get_task_allow" ]]; then
  /usr/libexec/PlistBuddy -c "Add :get-task-allow bool $get_task_allow" "$output_path"
fi

/usr/libexec/PlistBuddy -c "Add :keychain-access-groups array" "$output_path"
/usr/libexec/PlistBuddy -c "Add :keychain-access-groups:0 string $expected_application_identifier" "$output_path"

plutil -lint "$output_path" >/dev/null
