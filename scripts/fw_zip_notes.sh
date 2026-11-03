#!/usr/bin/env bash
# Cetak bagian catatan rilis untuk zip flashable. Pakai: fw_zip_notes.sh <zip>
set -euo pipefail
z=$1; n=$(basename "$z")
cat <<TXT
<!-- flashable -->
### Zip flashable (TWRP / OrangeFox)

\`${n}\` ($(du -h "$z" | cut -f1)) — sha256 \`$(sha256sum "$z" | cut -d' ' -f1)\`

Isi: semua image di atas, di-flash ke **slot A dan B**. Boot, recovery, ROM (super) dan data **tidak disentuh**.

Pengaman di installer:
- cek device = ingres, semua partisi ada, ukuran image <= partisi
- cek sha256 tiap image di dalam zip sebelum menulis apa pun
- tulis slot non-aktif dulu, baca ulang & cocokkan hash, baru slot aktif

Cara: Recovery > Install > pilih zip > swipe. Setelah itu flash ROM atau reboot.
TXT
