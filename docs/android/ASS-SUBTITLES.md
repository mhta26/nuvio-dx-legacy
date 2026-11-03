# Android ASS/SSA subtitles (2.0.8)

Android TV and Mobile use the shared libass renderer for external ASS/SSA and
embedded Matroska ASS/SSA. Authored styles, simultaneous events, positioning,
colours and karaoke are passed to libass; MKV font attachments are read by the
existing bounded Range collector. HarfBuzz and FriBidi provide complex Arabic
shaping and bidirectional layout. SDL_ttf and libass share one FreeType build.

Media3 `Format.id` identifies the Matroska TrackNumber. A background Tracks probe
maps that number to the file's subtitle ordinal, including subtitle tracks hidden
by Media3. Unsupported or unidentifiable tracks are never matched by guesswork.
The shared subtitle controller disables native cues while its ASS overlay is
active and retains its existing extraction failure fallback. Seek, delay and
track changes use the same controller as the other native targets.

## Arabic anime source preference

With **Arabic selected as the subtitle language** and **Best source** selection,
Android gives anime sources with declared embedded Arabic ASS/SSA a bounded
bonus within the existing quality band. Anime uses the existing title classifier
(Kitsu/MAL/AniList IDs, or Japanese animation metadata). Other titles and other
subtitle languages retain their ordering. First source mode preserves addon
order, and explicit remembered source choices retain priority. Cache, maximum
quality, decoder compatibility and connection-fit penalties remain in force.

AIOStreams Stable must expose `streamData.parsedFile.subtitleTracks` (or the
existing `clientResolve.stream.raw.parsed` path), with `mediaInfoQuality` set to
`probe` or `indexer`. A single track must declare both Arabic (`ar`, `ara`,
`Arabic`, or an `ar-*` language tag) and `ass`, `ssa`, `S_TEXT/ASS` or `S_TEXT/SSA`.
Names, filename hints, language lists without track codecs, external subtitles,
and Arabic SRT plus English ASS do not establish this evidence. Older Stable
responses without these fields remain playable with their existing ordering;
the client does not scan every candidate video to guess its subtitle content.

## Build and performance

`tools/android.sh` builds the pinned static dependencies through
`tools/android/ass.sh` for arm64-v8a and armeabi-v7a. The latter also accepts one
ABI for targeted development. Set `ANDROID_NDK_HOME` and optionally
`NUVIO_ANDROID_CACHE` and `NUVIO_ANDROID_JOBS` (default 4). CMake, Meson, Ninja,
pkg-config and make are required. Archive SHA-256 checks are mandatory. The
normal APK build stages dependency licence notices with its assets.

For direct Android Studio/Gradle builds, first run the dependency script and set
`-Pnuvio.assRoot=<cache>/ass-prefix` when using a nondefault cache. CMake fails
explicitly if the renderer dependencies are absent.

Source preference performs no network requests. Ordinary SRT/VTT playback does
not trigger the new Tracks probe; probing runs only when Media3 declares an ASS
track. libass starts on subtitle demand, rendering runs on the existing worker,
and Android's bitmap cache is capped at 16 MiB and accumulated embedded fonts at
32 MiB. These are individual cache limits, not a bound on total process memory.
No video/audio software decoder or playback transcode is added.

Validation commands:

```sh
bash tests/android_ass_sources.sh
bash tests/video_android_ass.sh  # NDK + cached SDL headers, as in other JNI tests
bash tests/stream_parser.sh
bash tests/faixasmkv_casar.sh
```

Real-TV rendering, playback timing and memory pressure should also be checked
with an Arabic ASS MKV containing attached fonts; host tests and cross-builds do
not substitute for a device playback test.
