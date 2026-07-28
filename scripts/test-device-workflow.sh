#!/usr/bin/env bash

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$repository_root/.github/workflows/ios-device-build.yml"

if ! rg -q '^      device_preview:$' "$workflow"; then
  echo "GitHub cihaz iş akışında önizleme/üretim seçimi bulunamadı." >&2
  exit 1
fi

if ! rg -q "MASALCI_DEVICE_PREVIEW:.*inputs\.device_preview.*'NO'.*'YES'" "$workflow"; then
  echo "Manuel üretim seçimi MASALCI_DEVICE_PREVIEW değerine bağlanmamış." >&2
  exit 1
fi

if ! rg -q "MASALCI_BUILD_CONFIGURATION:.*inputs\.device_preview.*'Release'.*'Debug'" "$workflow"; then
  echo "Üretim cihaz paketi Release yapılandırmasına bağlanmamış." >&2
  exit 1
fi

if ! rg -U -q '  build:\n    env:\n      MASALCI_DEVICE_PREVIEW:.*\n      MASALCI_BUILD_CONFIGURATION:' "$workflow"; then
  echo "Cihaz modu ile yapılandırması paketleme adımına taşınacak iş seviyesinde değil." >&2
  exit 1
fi

device_build_step=$(node -e '
  const fs = require("node:fs");
  const value = fs.readFileSync(process.argv[1], "utf8");
  const match = value.match(/      - name: İmzasız cihaz uygulamasını derle\n[\s\S]*?(?=\n      - name: )/);
  if (!match) process.exit(1);
  process.stdout.write(match[0]);
' "$workflow")

if ! rg -q -- '-configuration "\$MASALCI_BUILD_CONFIGURATION"' <<<"$device_build_step"; then
  echo "Cihaz derlemesi seçilen Debug/Release yapılandırmasını kullanmıyor." >&2
  exit 1
fi

if ! rg -q 'MASALCI_DEVICE_PREVIEW="\$MASALCI_DEVICE_PREVIEW"' <<<"$device_build_step"; then
  echo "Cihaz derlemesi seçilen önizleme/üretim modunu kullanmıyor." >&2
  exit 1
fi

package_step=$(node -e '
  const fs = require("node:fs");
  const value = fs.readFileSync(process.argv[1], "utf8");
  const match = value.match(/      - name: Uygulama paketini hazırla\n[\s\S]*?(?=\n      - name: )/);
  if (!match) process.exit(1);
  process.stdout.write(match[0]);
' "$workflow")

if ! rg -q 'Build/Products/\$MASALCI_BUILD_CONFIGURATION-iphoneos' <<<"$package_step"; then
  echo "Paketleme adımı seçilen Debug/Release çıktı dizinini kullanmıyor." >&2
  exit 1
fi

echo "GitHub cihaz önizleme/üretim seçimi testi geçti."
