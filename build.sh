#!/usr/bin/env bash
set -euo pipefail

year="${YEAR:-$(date -u +%Y)}"
month="${MONTH:-$(date -u +%m)}"

root="https://releases.mozilla.org/pub/fenix/nightly/${year}/${month}/"

build_dir="$(
  curl -fsSL "$root" \
  | grep -oE "/pub/fenix/nightly/${year}/${month}/[^\"']+/" \
  | sed -E 's#^/pub/fenix/nightly/'"${year}/${month}"'/##' \
  | grep -E "^${year}-${month}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-fenix-${BUILD_VERSION}-android/$" \
  | sort \
  | tail -n 1
)"

base="${root}${build_dir}"

apk_name="$(
  curl -fsSL "$base" \
  | sed -nE 's/.*href="([^"]*fenix-[^"]*\.multi\.android-universal\.apk)".*/\1/p' \
  | head -n 1 \
  | xargs -n1 basename
)"

apk_url="${base}${apk_name}"
curl -fL "$apk_url" -o latest.apk

wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.12.0/apktool_2.12.0.jar -O apktool.jar
wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
chmod +x apktool*

rm -rf patched patched_signed.apk
./apktool d latest.apk -o patched
rm -rf patched/META-INF

sed -i 's/<color name="fx_mobile_surface">.*/<color name="fx_mobile_surface">#ff000000<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_background">.*/<color name="fx_mobile_background">#ff000000<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' patched/res/values-night/colors.xml
sed -i 's/ff2b2a33/ff000000/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff32313c/ff000000/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff42414d/ff15141a/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff52525e/ff15141a/g' patched/smali_classes2/mozilla/components/ui/colors/PhotonColors.smali

./apktool b patched -o patched.apk

zipalign 4 patched.apk patched_signed.apk
rm -rf patched patched.apk
