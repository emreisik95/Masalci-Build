#!/usr/bin/env bash

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$repository_root/.github/workflows/ios-device-build.yml"

node - "$workflow" <<'NODE'
const fs = require("node:fs");
const workflow = fs.readFileSync(process.argv[2], "utf8");

function assert(condition, message) {
  if (!condition) {
    process.stderr.write(`${message}\n`);
    process.exit(1);
  }
}

function step(name) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = workflow.match(new RegExp(`      - name: ${escaped}\\n[\\s\\S]*?(?=\\n      - name: )`));
  assert(match, `GitHub cihaz iş akışında '${name}' adımı bulunamadı.`);
  return match[0];
}

assert(/^      device_preview:$/m.test(workflow), "GitHub cihaz iş akışında önizleme/üretim seçimi bulunamadı.");
assert(/MASALCI_DEVICE_PREVIEW:.*inputs\.device_preview.*'NO'.*'YES'/.test(workflow), "Manuel üretim seçimi MASALCI_DEVICE_PREVIEW değerine bağlanmamış.");
assert(/MASALCI_BUILD_CONFIGURATION:.*inputs\.device_preview.*'Release'.*'Debug'/.test(workflow), "Üretim cihaz paketi Release yapılandırmasına bağlanmamış.");
assert(/  build:\n    env:\n      MASALCI_DEVICE_PREVIEW:.*\n      MASALCI_BUILD_CONFIGURATION:/.test(workflow), "Cihaz modu ile yapılandırması paketleme adımına taşınacak iş seviyesinde değil.");

const deviceBuild = step("İmzasız cihaz uygulamasını derle");
assert(deviceBuild.includes('-configuration "$MASALCI_BUILD_CONFIGURATION"'), "Cihaz derlemesi seçilen Debug/Release yapılandırmasını kullanmıyor.");
assert(deviceBuild.includes('MASALCI_DEVICE_PREVIEW="$MASALCI_DEVICE_PREVIEW"'), "Cihaz derlemesi seçilen önizleme/üretim modunu kullanmıyor.");

const packaging = step("Uygulama paketini hazırla");
assert(packaging.includes("Build/Products/$MASALCI_BUILD_CONFIGURATION-iphoneos"), "Paketleme adımı seçilen Debug/Release çıktı dizinini kullanmıyor.");
NODE

echo "GitHub cihaz önizleme/üretim seçimi testi geçti."
