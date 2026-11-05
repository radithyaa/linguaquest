#!/usr/bin/env bash
# Build library native lq_bridge (mesin bisnis lq_core) untuk Android & Desktop,
# lalu salin ke folder jniLibs sehingga aplikasi Flutter memuat .so dalam satu
# proses biner (SRS 3.3).
#
# Pemakaian:
#   ./scripts/build_bridge.sh              # semua ABI Android + Linux desktop
#   ./scripts/build_bridge.sh android      # hanya Android
#   ./scripts/build_bridge.sh linux        # hanya Linux desktop
set -euo pipefail

cd "$(dirname "$0")/.."

TARGETS_ANDROID=(aarch64-linux-android armv7-linux-androideabi x86_64-linux-android)
TARGET_LINUX=x86_64-unknown-linux-gnu
JNILIBS="apps/app/android/app/src/main/jniLibs"

export CARGO_PROFILE_DEV_DEBUG="${CARGO_PROFILE_DEV_DEBUG:-0}"

ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
NDK_DIR="${NDK_DIR:-$(ls -d "$ANDROID_SDK"/ndk/* 2>/dev/null | sort -V | tail -1)}"

profile_flag=()
[ "${1:-}" = "--release" ] && profile_flag=(--release) || true
mode="${1:-all}"
[ "$mode" = "--release" ] && mode="all"

build_android() {
  if [ -z "${NDK_DIR:-}" ] || [ ! -d "$NDK_DIR" ]; then
    echo "NDK Android tidak ditemukan di $ANDROID_SDK/ndk — lewati build Android."
    return 0
  fi
  local bin="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin"
  export PATH="$bin:$PATH"
  local api=23

  export CC_aarch64_linux_android="$bin/aarch64-linux-android${api}-clang"
  export AR_aarch64_linux_android="$bin/llvm-ar"
  export CC_armv7_linux_androideabi="$bin/armv7a-linux-androideabi${api}-clang"
  export AR_armv7_linux_androideabi="$bin/llvm-ar"
  export CC_x86_64_linux_android="$bin/x86_64-linux-android${api}-clang"
  export AR_x86_64_linux_android="$bin/llvm-ar"
  export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$bin/aarch64-linux-android${api}-clang"
  export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$bin/armv7a-linux-androideabi${api}-clang"
  export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$bin/x86_64-linux-android${api}-clang"

  local dir_map=(
    "aarch64-linux-android:arm64-v8a"
    "armv7-linux-androideabi:armeabi-v7a"
    "x86_64-linux-android:x86_64"
  )

  for target in "${TARGETS_ANDROID[@]}"; do
    echo "== build $target"
    cargo build -p lq_bridge --target "$target" "${profile_flag[@]}"
    local abi=""
    for entry in "${dir_map[@]}"; do
      [ "${entry%%:*}" = "$target" ] && abi="${entry##*:}"
    done
    mkdir -p "$JNILIBS/$abi"
    cp "target/$target/$(profile_dir)/liblq_bridge.so" "$JNILIBS/$abi/liblq_bridge.so"
    echo "   -> $JNILIBS/$abi/liblq_bridge.so"
  done
}

build_linux() {
  echo "== build $TARGET_LINUX"
  cargo build -p lq_bridge --target "$TARGET_LINUX" "${profile_flag[@]}"
  mkdir -p apps/app/linux/lib
  cp "target/$TARGET_LINUX/$(profile_dir)/liblq_bridge.so" apps/app/linux/lib/liblq_bridge.so
  echo "   -> apps/app/linux/lib/liblq_bridge.so"
}

profile_dir() {
  if [ "${#profile_flag[@]}" -gt 0 ]; then echo "release"; else echo "debug"; fi
}

case "$mode" in
  android) build_android ;;
  linux) build_linux ;;
  all) build_android; build_linux ;;
  *) echo "Argumen tidak dikenal: $mode (pakai: android|linux|all|--release)"; exit 1 ;;
esac

echo "Selesai."
