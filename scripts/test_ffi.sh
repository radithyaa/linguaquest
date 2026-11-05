#!/usr/bin/env bash
# Uji integrasi FFI: Dart memuat liblq_bridge.so hasil build Rust lalu
# memanggil fungsi lq_core (evaluasi jawaban, XP, FSRS).
#
# Pemakaian: ./scripts/test_ffi.sh
set -euo pipefail

cd "$(dirname "$0")/.."

SO="target/x86_64-unknown-linux-gnu/debug/liblq_bridge.so"
if [ ! -f "$SO" ]; then
  echo "Library belum ada, menjalankan ./scripts/build_bridge.sh linux..."
  ./scripts/build_bridge.sh linux
fi

export LD_LIBRARY_PATH="$PWD/target/x86_64-unknown-linux-gnu/debug:${LD_LIBRARY_PATH:-}"
dart run scripts/ffi_smoke.dart "$SO"
