#!/usr/bin/env bash
# =============================================================================
#  make_fw_zip.sh - bungkus image firmware jadi zip flashable TWRP/OrangeFox
#
#  Pakai:  make_fw_zip.sh <folder_image> <versi> <output.zip> [device]
#    folder_image : folder berisi *.img (abl.img, xbl.img, modem.img, ...)
#    versi        : mis. OS2.0.8.0.ULJCNXM
#    output.zip   : path zip hasil
#    device       : default ingres
#
#  Isi zip:
#    META-INF/com/google/android/update-binary   (shell, cek + flash A/B)
#    META-INF/com/google/android/updater-script  (dummy)
#    images/*.img
#    SHA256SUMS, SHA1SUMS
# =============================================================================
set -euo pipefail

SRC=${1:?folder image wajib}
VERSION=${2:?versi wajib}
OUT=${3:?output zip wajib}
DEVICE=${4:-ingres}
HERE=$(cd "$(dirname "$0")" && pwd)

SRC=$(cd "$SRC" && pwd)
OUT=$(realpath -m "$OUT")

shopt -s nullglob
imgs=("$SRC"/*.img)
[ ${#imgs[@]} -gt 0 ] || { echo "tidak ada *.img di $SRC" >&2; exit 1; }

pkg=$(mktemp -d)
trap 'rm -rf "$pkg"' EXIT
mkdir -p "$pkg/META-INF/com/google/android" "$pkg/images"

names=""
for f in "${imgs[@]}"; do
    n=$(basename "$f")
    case "$n" in
        *[!a-z0-9_.]*) echo "nama file aneh: $n" >&2; exit 1 ;;
    esac
    ln "$f" "$pkg/images/$n" 2>/dev/null || cp "$f" "$pkg/images/$n"
    names="$names $n"
done
names=${names# }

(cd "$pkg/images" && sha256sum *.img > ../SHA256SUMS && sha1sum *.img > ../SHA1SUMS)

ub="$pkg/META-INF/com/google/android/update-binary"
sed -e "s|@DEVICE@|$DEVICE|g" \
    -e "s|@VERSION@|$VERSION|g" \
    -e "s|@IMAGES@|$names|g" \
    "$HERE/firmware-update-binary.in" > "$ub"
if grep -q '@[A-Z_]*@' "$ub"; then echo "placeholder update-binary belum terisi" >&2; exit 1; fi
chmod 0755 "$ub"
echo '# dummy - instalasi dijalankan oleh update-binary (shell)' \
    > "$pkg/META-INF/com/google/android/updater-script"

rm -f "$OUT"
(cd "$pkg" && zip -q -r -9 "$OUT" META-INF images SHA256SUMS SHA1SUMS)
echo "zip: $OUT ($(du -h "$OUT" | cut -f1))"
echo "image: $names"
