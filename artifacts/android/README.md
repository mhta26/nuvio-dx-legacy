# Android TV / Mobile ASS preview — 2.0.8

Download `Nuvio-2.0.8-android-debug.apk` from this directory. One APK supports
Android TV and Android phones/tablets on arm64-v8a and armeabi-v7a (Android 7+).

This is a debug-signed preview of commit
`65b35a07edfee3deb2b297cebef9e3db5195728d`, with libass, MKV attachment fonts and
the declared embedded Arabic ASS/SSA anime source preference. Its application ID
is `space.nuvio.nativelegacy.strictdebug`, so it installs alongside production.

**Account login is not configured.** The upstream server client configuration
was not available for this build. It needs the legitimate `local.properties`
configuration and a rebuild before account login can work.

The APK signature and 16 KB native-library alignment checks passed. Device
playback and performance have not been verified on a physical TV or phone.
See `SHA256SUMS` for the file digest.
