#!/usr/bin/env bash
# Static libass + complex Arabic shaping for Android (same renderer as webOS).
# Usage: ANDROID_NDK_HOME=... bash tools/android/ass.sh [arm64-v8a armeabi-v7a]
set -euo pipefail
cd "$(dirname "$0")/../.."
CACHE="${NUVIO_ANDROID_CACHE:-$HOME/.cache/nuvio-android}"
NDK="${ANDROID_NDK_HOME:-${ANDROID_HOME:-$HOME/Android/Sdk}/ndk/27.2.12479018}"
case "$(uname -s)" in Linux) host=linux-x86_64;; Darwin) host=darwin-x86_64;; *) exit 2;; esac
TC="$NDK/toolchains/llvm/prebuilt/$host"
[ -x "$TC/bin/clang" ] || { echo "Android NDK missing: $NDK" >&2; exit 2; }
for tool in cmake meson ninja pkg-config make; do command -v "$tool" >/dev/null; done
JOBS="${NUVIO_ANDROID_JOBS:-4}"
SRC="$CACHE/ass-src"; mkdir -p "$SRC"
fetch() {
  local name="$1" url="$2" checksum="$3"
  [ -f "$SRC/$name" ] || { curl -fL --retry 3 "$url" -o "$SRC/$name.part"; mv "$SRC/$name.part" "$SRC/$name"; }
  printf '%s  %s\n' "$checksum" "$SRC/$name" | shasum -a 256 -c -
}
# Checksums pin the exact upstream release archives; never build a partial download.
fetch freetype.tar.gz https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-3.tar.gz bc5c898e4756d373e0d991bab053036c5eb2aa7c0d5c67e8662ddc6da40c4103
fetch fribidi.tar.xz https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz 1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c
fetch harfbuzz.tar.xz https://github.com/harfbuzz/harfbuzz/releases/download/10.4.0/harfbuzz-10.4.0.tar.xz 480b6d25014169300669aa1fc39fb356c142d5028324ea52b3a27648b9beaad8
fetch libass.tar.xz https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz 2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc
abis=("$@"); [ ${#abis[@]} -gt 0 ] || abis=(arm64-v8a armeabi-v7a)
for abi in "${abis[@]}"; do
  case "$abi" in
    arm64-v8a) triple=aarch64-linux-android; cpu=aarch64;;
    armeabi-v7a) triple=armv7a-linux-androideabi; cpu=arm;;
    x86_64) triple=x86_64-linux-android; cpu=x86_64;;
    *) echo "Unsupported ABI: $abi" >&2; exit 2;;
  esac
  P="$CACHE/ass-prefix/$abi"; B="$CACHE/ass-build/$abi"
  signature="$(cksum < tools/android/ass.sh) $(cksum < "$NDK/source.properties")"
  if [ -f "$P/lib/libass.a" ] && [ "$(cat "$P/recipe" 2>/dev/null || true)" = "$signature" ]; then continue; fi
  mkdir -p "$P" "$B"
  for archive in freetype.tar.gz fribidi.tar.xz harfbuzz.tar.xz libass.tar.xz; do tar -xf "$SRC/$archive" -C "$B"; done
  # No host pkg-config packages may leak into this cross build.
  export PKG_CONFIG_LIBDIR="$P/lib/pkgconfig" PKG_CONFIG_PATH="$P/lib/pkgconfig"
  export PKG_CONFIG_SYSROOT_DIR=""
  export CC="$TC/bin/${triple}24-clang" CXX="$TC/bin/${triple}24-clang++"
  export AR="$TC/bin/llvm-ar" RANLIB="$TC/bin/llvm-ranlib" STRIP="$TC/bin/llvm-strip"
  export CFLAGS='-O2 -fPIC' CXXFLAGS='-O2 -fPIC' LDFLAGS="-L$P/lib"
  cmake -S "$B/freetype-VER-2-13-3" -B "$B/ft-build" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" -DANDROID_PLATFORM=android-24 -DANDROID_STL=c++_static \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$P" -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_ZLIB=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_PNG=ON -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_HARFBUZZ=ON
  cmake --build "$B/ft-build" -j "$JOBS"; cmake --install "$B/ft-build"
  cat > "$B/cross.ini" <<CROSS
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
pkg-config = '$(command -v pkg-config)'
[host_machine]
system = 'android'
cpu_family = '$cpu'
cpu = '$cpu'
endian = 'little'
[built-in options]
c_args = ['-O2', '-fPIC']
cpp_args = ['-O2', '-fPIC']
CROSS
  meson setup --wipe "$B/fri-build" "$B/fribidi-1.0.16" --cross-file "$B/cross.ini" --prefix "$P" --libdir lib \
    --buildtype release -Ddefault_library=static -Ddocs=false -Dbin=false -Dtests=false
  meson compile -C "$B/fri-build" -j "$JOBS"; meson install -C "$B/fri-build"
  meson setup --wipe "$B/hb-build" "$B/harfbuzz-10.4.0" --cross-file "$B/cross.ini" --prefix "$P" --libdir lib \
    --buildtype release -Ddefault_library=static -Dglib=disabled -Dgobject=disabled -Dgraphite=disabled -Dicu=disabled -Dcairo=disabled \
    -Dtests=disabled -Ddocs=disabled -Dutilities=disabled -Dfreetype=enabled
  meson compile -C "$B/hb-build" -j "$JOBS"; meson install -C "$B/hb-build"
  (cd "$B/libass-0.17.5"
   ./configure --host="$triple" --prefix="$P" --enable-static --disable-shared \
     --disable-fontconfig --disable-require-system-font-provider --disable-asm
   make -j "$JOBS"; make install)
  mkdir -p "$P/licenses"
  cp "$B/libass-0.17.5/COPYING" "$P/licenses/libass.txt"
  cp "$B/harfbuzz-10.4.0/COPYING" "$P/licenses/harfbuzz.txt"
  cp "$B/fribidi-1.0.16/COPYING" "$P/licenses/fribidi.txt"
  cp "$B/freetype-VER-2-13-3/docs/FTL.TXT" "$P/licenses/freetype.txt"
  printf '%s\n' "$signature" > "$P/recipe"
done
