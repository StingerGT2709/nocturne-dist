#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

SDK="${LOCALAPPDATA}/Android/Sdk"
BT="$SDK/build-tools/36.1.0"
ANDROID_JAR="$SDK/platforms/android-34/android.jar"
JDK="/c/Program Files/Java/jdk-17"
OUT="build"
APK_NAME="nocturne.apk"
KS_PASS="${KS_PASS:?키스토어 비밀번호를 환경변수 KS_PASS로 지정하세요 (예: KS_PASS=nocturne bash build.sh)}"

for f in "$BT/aapt2.exe" "$BT/zipalign.exe" "$BT/apksigner.bat" "$BT/d8.bat" "$ANDROID_JAR" "$JDK/bin/javac"; do
  [ -e "$f" ] || { echo "빠진 도구: $f"; exit 1; }
done

rm -rf "$OUT"; mkdir -p "$OUT/classes" "$OUT/dex"

echo "[1/7] 최신 index.html을 assets로 복사"
cp ../index.html assets/index.html

echo "[2/7] aapt2 compile (리소스)"
"$BT/aapt2.exe" compile --dir res -o "$OUT/res.zip"

echo "[3/7] aapt2 link (매니페스트 + assets)"
"$BT/aapt2.exe" link \
  -o "$OUT/base.apk" \
  -I "$ANDROID_JAR" \
  --manifest AndroidManifest.xml \
  -R "$OUT/res.zip" \
  -A assets \
  --min-sdk-version 24 \
  --target-sdk-version 34 \
  --version-code 2 \
  --version-name 1.1

echo "[4/7] javac"
"$JDK/bin/javac" --release 11 -encoding UTF-8 -nowarn \
  -cp "$(cygpath -w "$ANDROID_JAR")" \
  -d "$OUT/classes" \
  src/com/nocturne/release/MainActivity.java

echo "[5/7] d8 (dex 변환)"
"$BT/d8.bat" --release --min-api 24 \
  --lib "$(cygpath -w "$ANDROID_JAR")" \
  --output "$(cygpath -w "$OUT/dex")" \
  "$OUT"/classes/com/nocturne/release/*.class

echo "[6/7] classes.dex를 APK에 추가"
python - "$OUT" <<'PY'
import sys, zipfile, shutil, os
out = sys.argv[1]
shutil.copy(os.path.join(out, 'base.apk'), os.path.join(out, 'unsigned.apk'))
with zipfile.ZipFile(os.path.join(out, 'unsigned.apk'), 'a', zipfile.ZIP_DEFLATED) as z:
    z.write(os.path.join(out, 'dex', 'classes.dex'), 'classes.dex')
print('    classes.dex 추가 완료')
PY

echo "[7/7] zipalign + 서명"
if [ ! -f nocturne.jks ]; then
  "$JDK/bin/keytool" -genkeypair -v -keystore nocturne.jks -alias nocturne \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -dname "CN=Nocturne, OU=App, O=Nocturne, L=Seoul, C=KR" >/dev/null 2>&1
  echo "    키스토어 생성 (nocturne.jks)"
fi
"$BT/zipalign.exe" -f -p 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"
"$BT/apksigner.bat" sign \
  --ks nocturne.jks --ks-pass "pass:$KS_PASS" --key-pass "pass:$KS_PASS" \
  --v1-signing-enabled true --v2-signing-enabled true \
  --out "../$APK_NAME" "$OUT/aligned.apk"

"$BT/apksigner.bat" verify --print-certs "../$APK_NAME" | head -3
echo ""
echo "완료: $(cd .. && pwd)/$APK_NAME  ($(stat -c%s "../$APK_NAME") bytes)"
