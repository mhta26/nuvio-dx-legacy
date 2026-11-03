# Android TV / Mobile ASS + Login preview — 2.0.8

Download `Nuvio-2.0.8-android-debug.apk` from this directory. One APK supports
Android TV and Android phones/tablets on arm64-v8a and armeabi-v7a (Android 7+).

This preview includes libass, MKV attachment fonts and the declared embedded
Arabic ASS/SSA anime source preference from commit
`65b35a07edfee3deb2b297cebef9e3db5195728d`.

The public Nuvio login client configuration has now been restored from the
official upstream v2.0.8 Android release, after verifying its release SHA-256.
Only its public anonymous client key and login endpoints were used; no account
tokens or private signing keys were copied. The private local build configuration
file is excluded from Git and the APK.

Application ID: `space.nuvio.nativelegacy.strictdebug`. This debug-signed APK
installs alongside production and has the same signing certificate as the
previous preview, so it can update that preview.

APK signature, both ABIs' embedded login configuration, Arabic fonts, renderer
licences and 16 KB alignment checks passed. Local mocked email-login and login
transport regression tests passed (the latter needed the existing host harness's
missing persistence hook stub). Real account authorization and physical TV/phone
playback have not been verified; this build environment blocks the live login
service until its proposed network configuration is applied.

See `SHA256SUMS` for the APK digest. The older APK at commit `8ae093752` lacks
login configuration; download the latest file on this branch instead.
